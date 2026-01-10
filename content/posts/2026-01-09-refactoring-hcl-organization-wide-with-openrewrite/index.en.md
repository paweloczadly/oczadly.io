---
title: "Refactoring HCL organization-wide with OpenRewrite"
subtitle: "Safe OpenTofu and AVM module migrations in practice."
code:
  maxShownLines: 60
date: 2026-01-09
description: "Safe OpenTofu and AVM module migrations in practice."
draft: false
resources:
- name: "featured-image"
  src: "featured-image.png"
---

At some point, every larger infrastructure-as-code project reaches a stage where changes stop being local. Updating a module version, changing an input contract, or migrating between architectural approaches suddenly requires coordinated changes across many places and often across multiple repositories.

In theory, these are _"simple"_ updates: bumping a version, removing an input, adding a new configuration block. In practice, manually refactoring such changes is time-consuming, error-prone, and difficult to review safely. Text-based scripts built around tools like `grep` or `sed` help only up to a point. They do not understand the structure of the configuration, are sensitive to formatting, and, most importantly, **are not deterministic**. Each execution requires another round of manual verification to ensure the result is actually correct.

In this article, I show how to approach infrastructure-as-code migrations in a deterministic, repeatable, and safe way, using lossless, structure-aware refactoring rather than text-based transformations. Using real-world [Azure Verified Modules](https://azure.github.io/Azure-Verified-Modules/) (AVM) module migrations as examples, I demonstrate how to produce changes that land as clean, reviewable pull requests instead of manual edits scattered across a repository.

## Why OpenRewrite

The key difference between structural refactoring and traditional text-based tooling is that changes are applied to the **semantic structure of the configuration**, not to its raw textual representation. [OpenRewrite](https://docs.openrewrite.org/) is built around _lossless semantic trees (LST)_. It's a representation that preserves all information from the original source files, including formatting, comments, and ordering, while still allowing safe, semantic transformations.

In practice, this means refactorings operate on real configuration elements. For example modules, inputs, and blocks rather than on arbitrary lines of text. As a result, migrations become **deterministic**. The same input always produces the same output, regardless of formatting or stylistic differences. They are also **idempotent**. Running the same migration multiple times does not accumulate changes or introduce duplicates.

An important side effect of this approach is the quality of the output itself. Because [OpenRewrite](https://docs.openrewrite.org/) preserves the original structure of the files, the result of a migration lands in the repository as a clean, predictable diff, ready for a standard code review. The migration becomes a normal engineering operation, ending in a pull request instead of a one-off script that requires manual inspection and caution.

{{< admonition tip "This approach goes beyond HCL" >}}

It's also worth noting that this approach is not limited to HCL or [OpenTofu](https://opentofu.org/) / [Terraform](https://developer.hashicorp.com/terraform). [OpenRewrite](https://docs.openrewrite.org/) provides similar, structure-aware refactoring capabilities for other configuration formats, including YAML used across the [Kubernetes](https://kubernetes.io/) ecosystem ([Helm](https://helm.sh/), [Flux](https://fluxcd.io/), [Argo CD](https://argoproj.github.io/cd/)).

This means the same workflow: explicit recipes, deterministic execution, and pull requests as output can be applied to [Kubernetes](https://kubernetes.io/) manifest migrations, API changes, or GitOps refactoring. This, however, deserves a separate case study.

{{< /admonition >}}

## Case study

Poniżej przedstawiam konkretną migrację modułu [avm-res-network-virtualnetwork](https://registry.terraform.io/modules/Azure/avm-res-network-virtualnetwork/azurerm/0.10.0) z wersji 0.10.x do 0.11.x. Jest to dobry przykład zmian, które w praktyce można przeprowadzić ręcznie, ale wymagają jednoczesnego uwzględnienia zmiany wersji modułu, usunięcia przestarzałych parametrów oraz wprowadzenia nowego, wymaganego parametru zgodnie z [breaking changes](https://github.com/Azure/terraform-azurerm-avm-res-network-virtualnetwork/releases/tag/v0.11.0) w nowszej wersji.

Below is a concrete migration of the [avm-res-network-virtualnetwork](https://registry.terraform.io/modules/Azure/avm-res-network-virtualnetwork/azurerm/0.10.0) module from version 0.10.x to 0.11.x. This is a good example of changes that are theoretically manageable by hand but, in practice, require coordinated updates: bumping the module version, removing deprecated inputs, and introducing a new requried parameter according to the module's [breaking changes](https://github.com/Azure/terraform-azurerm-avm-res-network-virtualnetwork/releases/tag/v0.11.0).

```yaml
---
# More information about breaking changes for the 0.11.x release can be found at:
# https://github.com/Azure/terraform-azurerm-avm-res-network-virtualnetwork/releases/tag/v0.11.0
type: specs.openrewrite.org/v1beta/recipe
name: io.oczadly.avm.migrations.res.network.virtualnetwork.From010xTo011x
displayName: avm-res-network-virtualnetwork 0.10.x -> 0.11.x
description: Migrate avm-res-network-virtualnetwork from 0.10.x to 0.11.x
recipeList:
  # Switch module version from "~> 0.10.0" to "~> 0.11.0" first:
  - io.oczadly.openrewrite.hcl.ChangeModuleVersion:
      source: "Azure/avm-res-network-virtualnetwork/azurerm"
      version: "~> 0.10.0"
      newVersion: "~> 0.11.0"
  # Then remove deprecated inputs:
  - io.oczadly.openrewrite.hcl.RemoveModuleInput:
      source: "Azure/avm-res-network-virtualnetwork/azurerm"
      version: "~> 0.11.0"
      inputName: resource_group_name
  - io.oczadly.openrewrite.hcl.RemoveModuleInput:
      source: "Azure/avm-res-network-virtualnetwork/azurerm"
      version: "~> 0.11.0"
      inputName: subscription_id
  # Finally, add new required inputs:
  - io.oczadly.openrewrite.hcl.AddModuleInput:
      source: "Azure/avm-res-network-virtualnetwork/azurerm"
      version: "~> 0.11.0"
      inputName: parent_id
      inputValueProperty: avm.vnet.parent_id
```

The migration is expressed as a single [OpenRewrite](https://docs.openrewrite.org/) recipe that explicitly defines both the scope and the order of changes: first updating the module version, then removing deprecated inputs, and finally adding a newly required one.

Already at the `rewriteDryRun` stage, it becomes clear that the same migration is applied **deterministically** and consistently accross multiple projects without manually pointing to the specific files or directories. Each change is directly tied to a specific recipe, which simplifies both review and auditing.

```shell
$ ./gradlew rewriteDryRun \
  -Drewrite.activeRecipes=io.oczadly.avm.migrations.res.network.virtualnetwork.From010xTo011x \
  -Davm.vnet.parent_id='${data.terraform_remote_state.rg_default_eastus.outputs.resource.id}'

> Task :rewriteDryRun
Validating active recipes
Scanning sources in project :
Using active styles []
All sources parsed, running active recipes: io.oczadly.avm.migrations.res.network.virtualnetwork.From010xTo011x
These recipes would make changes to projects/first-company/05-networking-vnets/first-company/rg-default-eastus/vnet-default-eastus/main.tf:
    io.oczadly.openrewrite.hcl.ChangeModuleVersion: {newVersion=~> 0.11.0}
        io.oczadly.openrewrite.hcl.RemoveModuleInput: {inputName=resource_group_name}
            io.oczadly.openrewrite.hcl.AddModuleInput: {inputName=parent_id, inputValueProperty=avm.vnet.parent_id}
These recipes would make changes to projects/second-company/05-networking-vnets/second-company/rg-default-eastus/vnet-default-eastus/main.tf:
    io.oczadly.openrewrite.hcl.ChangeModuleVersion: {newVersion=~> 0.11.0}
        io.oczadly.openrewrite.hcl.RemoveModuleInput: {inputName=resource_group_name}
            io.oczadly.openrewrite.hcl.AddModuleInput: {inputName=parent_id, inputValueProperty=avm.vnet.parent_id}
Report available:
    /opt/infra-at-scale/avm-openrewrite-migrations/build/reports/rewrite/rewrite.patch
Estimate time saved: 10m
Run 'gradle rewriteRun' to apply the recipes.

BUILD SUCCESSFUL in 1s
3 actionable tasks: 3 executed
```

The resulting change is local, written to a **rewrite.patch** file, and easy to understand. There are no unrelated modifications, and the diff directly reflects the scope described in the module's release notes.

```diff
diff --git a/projects/first-company/05-networking-vnets/first-company/rg-default-eastus/vnet-default-eastus/main.tf b/projects/first-company/05-networking-vnets/first-company/rg-default-eastus/vnet-default-eastus/main.tf
index 5162410..ff947b0 100644
--- a/projects/first-company/05-networking-vnets/first-company/rg-default-eastus/vnet-default-eastus/main.tf
+++ b/projects/first-company/05-networking-vnets/first-company/rg-default-eastus/vnet-default-eastus/main.tf
@@ -7,13 +7,12 @@ io.oczadly.avm.migrations.res.network.virtualnetwork.From010xTo011x
 
 module "vnet" {
   source  = "Azure/avm-res-network-virtualnetwork/azurerm"
-  version = "~> 0.10.0"
+  version = "~> 0.11.0"
 
   # Required:
-  address_space       = ["10.0.0.0/16"]
-  location            = data.terraform_remote_state.rg_default_eastus.outputs.resource.location
-  name                = module.naming.virtual_network.name
-  resource_group_name = data.terraform_remote_state.rg_default_eastus.outputs.resource.name
+  address_space = ["10.0.0.0/16"]
+  location      = data.terraform_remote_state.rg_default_eastus.outputs.resource.location
+  name          = module.naming.virtual_network.name
 
   # Optional:
   subnets = {
@@ -39,4 +38,5 @@
     Environment = "Non-Prod"
     /* Your other tagging conventions */
   }
+  parent_id = "${data.terraform_remote_state.rg_default_eastus.outputs.resource.id}"
 }

diff --git a/projects/second-company/05-networking-vnets/second-company/rg-default-eastus/vnet-default-eastus/main.tf b/projects/second-company/05-networking-vnets/second-company/rg-default-eastus/vnet-default-eastus/main.tf
index 5162410..ff947b0 100644
--- a/projects/second-company/05-networking-vnets/second-company/rg-default-eastus/vnet-default-eastus/main.tf
+++ b/projects/second-company/05-networking-vnets/second-company/rg-default-eastus/vnet-default-eastus/main.tf
@@ -7,13 +7,12 @@ io.oczadly.avm.migrations.res.network.virtualnetwork.From010xTo011x
 
 module "vnet" {
   source  = "Azure/avm-res-network-virtualnetwork/azurerm"
-  version = "~> 0.10.0"
+  version = "~> 0.11.0"
 
   # Required:
-  address_space       = ["10.0.0.0/16"]
-  location            = data.terraform_remote_state.rg_default_eastus.outputs.resource.location
-  name                = module.naming.virtual_network.name
-  resource_group_name = data.terraform_remote_state.rg_default_eastus.outputs.resource.name
+  address_space = ["10.0.0.0/16"]
+  location      = data.terraform_remote_state.rg_default_eastus.outputs.resource.location
+  name          = module.naming.virtual_network.name
 
   # Optional:
   subnets = {
@@ -39,4 +38,5 @@
     Environment = "Non-Prod"
     /* Your other tagging conventions */
   }
+  parent_id = "${data.terraform_remote_state.rg_default_eastus.outputs.resource.id}"
 }
```

At this point, the migration is ready to be applied using `rewriteRun` task:

```shell
$ ./gradlew rewriteRun \
  -Drewrite.activeRecipes=io.oczadly.avm.migrations.res.network.virtualnetwork.From010xTo011x \
  -Davm.vnet.parent_id='${data.terraform_remote_state.rg_default_eastus.outputs.resource.id}'
```

Finally, changes can be merged through the standard pull request workflow, without custom scripts, exceptions, or manual fixes.

## Architecture of the solution

The solution consits of a few clearly separated components:

1. Java recipes.
2. YAML recipes.
3. Gradle.

Each component has a distinct responsibility, and the separation keeps the system simple, testable and extensible.

### Java recipes

The [official OpenRewrite recipe catalog](https://docs.openrewrite.org/recipes) does not include recipes for changing [OpenTofu](https://opentofu.org/) / [Terraform](https://developer.hashicorp.com/terraform) module versions or adding / removing module inputs. For this reason, a custom set of recipes was created and published in [paweloczadly/openrewrite-recipes](https://github.com/paweloczadly/openrewrite-recipes).

Beyond implementing the required functionality, these recipes include a solid set of unit tests that directly verify their behavior and act as the first line of defense against unintended changes in HCL structure. The artifacts are published to [Maven Central](https://central.sonatype.com/artifact/io.oczadly/openrewrite-recipes/overview) via an automated CD pipeline.

This layer can be treated as a **refactoring engine**, independent of any specific migration or project.

### YAML recipes

The [infra-at-scale/avm-openrewrite-migrations](https://github.com/infra-at-scale/avm-openrewrite-recipes) repository contains YAML recipes that invoke the Java recipes described above. At this level, concrete AVM migrations are defined in a declarative and versionable form.

Each YAML recipe specifies __what__ should change: the target module version, removed inputs, and newly required parameters, without modifying the mechanics of refactoring itself. This clean separation makes migrations easy to review, test, and approve using standard code review processes.

In practices, YAML recipes for a __policy layer__, enabling repeatable, deterministic migrations accors one or many projects, regardless of repository layout.

### Gradle

To make these migrations repeatable, I run them through a [Gradle](https://gradle.org/) based workflow. [Gradle](https://gradle.org/) acts as the execution engine: it resolves [OpenRewrite](https://docs.openrewrite.org/) recipes, applies them consistently across repositories, and produces deterministic results that can be validated locally or in CI.

In environments where [Develocity](https://gradle.com/develocity/) is already in use, the same workflow can publish [Build Scans](https://docs.gradle.org/9.0.0/userguide/build_scans.html), making it easier to observe execution characteristics and compare the results across repositories – without changing the underlying workflow.

## Safety guarantees

Infrastructure as code migrations are not risky because they are technically complex, but because they are often **non-deterministic**, hard to verify, and executed ad hoc. In this approach, safety does not come from individual caution but from the properties of the process itself.

### Determinism

Each migration is described as an explicit [OpenRewrite](https://docs.openrewrite.org/) YAML recipe. For a given input state, the refactoring result is always the same. Regardless of who runs it or where. There is no reliance on regular expressions or environment-dependent matching order.

This is especially important in organizations where the same migration must be applied accross many repositories or environments.

### Indempotence

[OpenRewrite](https://docs.openrewrite.org/) recipes are indempotent. Running the same migration multiple times does not accumulate changes. Once applied, subsequent runs leave the code unchanged.

This makes migrations safe to:

- [x] Run repeatedly.
- [x] Integrate into CI.
- [x] Apply incrementally without drifting infrastructure state.

### Transparency and auditability

Both Java and YAML recipes live in Git repositories. The entire migration logic is visible, versioned, and subject to standard code review.

There are no:

- Hidden scripts.
- Dynamically generated commands.
- Changes performed outside the repository.

Additionally, Java recipes are published to [Maven Central](https://central.sonatype.com/artifact/io.oczadly/openrewrite-recipes/overview) via an automated CI/CD pipeline. While publication itself is not a guarantee of quality, it provides a verifiable, auditable supply-chain artifacts with clear provenance and immutability after release.

### Pre-flight validation

Running migrations in `rewriteDryRun` mode, similarly to `tofu plan` / `terraform plan`, allows inspecting the full scope of planned changes without modifying code. This creates space to asses impact, catch unexpected effects, and make informed decisions before applying changes.

## Why this scales accross organizations

This approach scales not because of the tools involved, but because it addresses the problem at the right level of abstraction. Migrations are treated not as one-off tasks performed manually in individual repositories, but as an explicitly described process that can be reused accross contexts.

Responsibilities are clearly separated:

- Java recipes define **HOW** safe HCL refactoring works.
- YAML recipes define **WHAT** changes in a given migration.
- [Gradle](https://gradle.org/) ensures repeatable execution locally and in CI.

As a result, the same migration can be applied across many repositories, executed by different teams, and integrated into existing CI/CD and code review workflows, without requiring a centralized platform.

## When this approach does not make sense

This approach is not a universal solution. For small IaC projects consisting of a single module with no planned evolution, the overhead of introducing an additional process may outweigh its benefits.

Similarly, for one-off, trivial changes, such as bumping a version in a single place, tools like [Renovate](https://docs.renovatebot.com/) or even manual edits may be simpler and more appropriate.

The approach also assumes a certain level of organizational maturity. Such as working with pull requests, code review, and treating migrations as part of long-term maintenance rather than incidental fixes.

## Summary

Infrastructure as code migrations are inevitable. Module versions change, cloud provider requirements evolve, and best practices shift. The challenge is not the change itself, but **how it is performed**.

This article demonstrated how to approach [OpenTofu](https://opentofu.org/) / [Terraform](https://developer.hashicorp.com/terraform) refactoring in a deterministic, repeatable, and safe way, by using [OpenRewrite](https://docs.openrewrite.org/) as the refactoring engine and Gradle as the execution mechanism. Instead of brittle `grep` and `sed` based scripts, the proposed approach relies on explicit recipes, minimal diffs, and pull requests as the sole output of the process.

As a result, migrations stop being risky, one-off events and becomes a **controlled engineering process** that can be audited, evolved, and safely applied accross an organization.

Importantly, the refactoring model presented here is not tied to a single format or tool. Explicit recipes, deterministic execution, and pull requests as the output form a universal approach to safely evolving infrastructure configuration.

{{< admonition example "What's next?" >}}

If you work with AVM or maintain large [OpenTofu](https://opentofu.org/) / [Terraform](https://developer.hashicorp.com/terraform) codebases and are thinking about how to approach migrations safely, this is a model you can try in practice.

👉 Explore the [infra-at-scale/avm-openrewrite-migrations](https://github.com/infra-at-scale/avm-openrewrite-recipes) repository and apply the migrations to your own projects.

If you are interested in extending the refactoring engine or contributing fixes and improvements:

👉 Fork [paweloczadly/openrewrite-recipes](https://github.com/paweloczadly/openrewrite-recipes) and build on top of it.

And if you are dealing with more complex migration scenarios in the [OpenTofu](https://opentofu.org/) / [Terraform](https://developer.hashicorp.com/terraform) ecosystem or across [Kubernetes](https://kubernetes.io/) configurations ([Helm](https://helm.sh/), [Flux](https://fluxcd.io/), [Argo CD](https://argoproj.github.io/cd/)), or want to discuss applying this approach in your organization:

👉 Contact me at [contact@oczadly.io](mailto:contact@oczadly.io).

{{< /admonition >}}

{{< buymeacoffee >}}
