---
title: "Refactoring HCL organization-wide with OpenRewrite"
subtitle: "Safe OpenTofu and AVM module migrations in practice."
code:
  maxShownLines: 70
date: 2026-04-23
description: "Safe OpenTofu and AVM module migrations in practice."
draft: false
resources:
- name: "featured-image"
  src: "featured-image.png"
---

At some point, every larger infrastructure-as-code project reaches a stage where changes stop being local. Updating a module version, changing an input contract, or migrating between architectural approaches suddenly requires coordinated changes across many places and often across multiple repositories.

In theory, these are _"simple"_ updates: bumping a version, removing an input, adding a new configuration block. In practice, manually refactoring such changes is time-consuming, error-prone, and difficult to review safely. Text-based scripts built around tools like `grep` or `sed` help only up to a point. They do not understand the structure of the configuration, are sensitive to formatting, and, most importantly, **are not deterministic**. Each execution requires another round of manual verification to ensure the result is actually correct.

In this article, I show how to approach infrastructure-as-code migrations in a deterministic, repeatable, and safe way, using lossless, structure-aware refactoring rather than text-based transformations. Using real-world [Azure Verified Modules](https://azure.github.io/Azure-Verified-Modules/) (AVM) module migrations as examples, I demonstrate how to produce changes that land as clean, reviewable pull requests instead of manual edits scattered across a repository.

---

## Why OpenRewrite

The key difference between structural refactoring and traditional text-based tooling is that changes are applied to the **semantic structure of the configuration**, not to its raw textual representation. [OpenRewrite](https://docs.openrewrite.org/) is built around _lossless semantic trees (LST)_. It's a representation that preserves all information from the original source files, including formatting, comments, and ordering, while still allowing safe, semantic transformations.

In practice, this means refactorings operate on real configuration elements. For example modules, inputs, and blocks rather than on arbitrary lines of text. As a result, migrations become **deterministic**. The same input always produces the same output, regardless of formatting or stylistic differences. They are also **idempotent**. Running the same migration multiple times does not accumulate changes or introduce duplicates.

An important side effect of this approach is the quality of the output itself. Because [OpenRewrite](https://docs.openrewrite.org/) preserves the original structure of the files, the result of a migration lands in the repository as a clean, predictable diff, ready for a standard code review. The migration becomes a normal engineering operation, ending in a pull request instead of a one-off script that requires manual inspection and caution.

{{< admonition tip "This approach goes beyond HCL" >}}

It's also worth noting that this approach is not limited to HCL or [OpenTofu](https://opentofu.org/) / [Terraform](https://developer.hashicorp.com/terraform). [OpenRewrite](https://docs.openrewrite.org/) provides similar, structure-aware refactoring capabilities for other configuration formats, including YAML used across the [Kubernetes](https://kubernetes.io/) ecosystem ([Helm](https://helm.sh/), [Flux](https://fluxcd.io/), [Argo CD](https://argoproj.github.io/cd/)).

This means the same workflow: explicit recipes, deterministic execution, and pull requests as output can be applied to [Kubernetes](https://kubernetes.io/) manifest migrations, API changes, or GitOps refactoring. This, however, deserves a separate case study.

{{< /admonition >}}

---

## Case study

### Simple example

Before diving into complexity, consider a straightforward case. The [avm-res-network-virtualnetwork](https://registry.terraform.io/modules/Azure/avm-res-network-virtualnetwork/azurerm/0.10.0) module underwent a contract change in version 0.11.0: removing `resource_group_name` and `subscription_id`, adding required `parent_id`. These are typical engineering changes: straightforward in concept, but risky to apply manually across many places.

The migration is described as an [OpenRewrite](https://docs.openrewrite.org/) recipe:

```yaml
type: specs.openrewrite.org/v1beta/recipe
name: io.oczadly.avm.migrations.res.network.virtualnetwork.From010xTo011x
displayName: avm-res-network-virtualnetwork 0.10.x -> 0.11.x
description: Migrate avm-res-network-virtualnetwork from 0.10.x to 0.11.x
recipeList:
  - io.oczadly.openrewrite.hcl.ChangeModuleVersion:
      source: "Azure/avm-res-network-virtualnetwork/azurerm"
      version: "~> 0.10.0"
      newVersion: "~> 0.11.0"
  - io.oczadly.openrewrite.hcl.RemoveModuleInput:
      source: "Azure/avm-res-network-virtualnetwork/azurerm"
      version: "~> 0.11.0"
      inputName: resource_group_name
  - io.oczadly.openrewrite.hcl.RemoveModuleInput:
      source: "Azure/avm-res-network-virtualnetwork/azurerm"
      version: "~> 0.11.0"
      inputName: subscription_id
  - io.oczadly.openrewrite.hcl.AddModuleInput:
      source: "Azure/avm-res-network-virtualnetwork/azurerm"
      version: "~> 0.11.0"
      inputName: parent_id
      inputValue: data.terraform_remote_state.rg_default_eastus.outputs.resource.name
```

That's it. The migration is immutable, repeatable, and ready for organization-wide deployment.

### Complex scenario

Now consider reality. The [avm-res-network-privatednszone](https://github.com/Azure/terraform-azurerm-avm-res-network-privatednszone/releases/tag/v0.4.0) module underwent a comprehensive refactoring in version 0.4.0. It's not just the contract that changed, but the module architecture itself: a shift from Azure resources to `azapi`, using `removed` and `import` blocks for state migration. This is no longer a simple change, this is a **complex, multi-step refactoring**.

#### What had to change

In the old version (0.3.x), the module managed resources directly via Azurerm resources: `azurerm_private_dns_zone`, `azurerm_private_dns_zone_virtual_network_link`, DNS records (`azurerm_private_dns_a_record`, etc.), and role assignments.

In the new version (0.4.0), everything shifted to `azapi_resource`. This means resources existing in [OpenTofu](https://opentofu.org/) / [Terraform](https://developer.hashicorp.com/terraform) state from version 0.3.x must be **migrated**, not destroyed and recreated. For production infrastructure, this is critical. Instead of destruction and reconstruction, we want to tell [OpenTofu](https://opentofu.org/) / [Terraform](https://developer.hashicorp.com/terraform): _"this resource exists where it is, but we will manage it differently now."_

#### Migration structure

The YAML recipe for this migration performs five operations:

**1. Environment setup**: adding required providers (`azapi`, `modtm`).

```yaml
- io.oczadly.openrewrite.hcl.AddProvider:
    source: "Azure/avm-res-network-privatednszone/azurerm"
    version: "~> 0.3.5"
    providerName: "azapi"
    providerSource: "azure/azapi"
    providerVersion: "~> 2.5.0"
```

**2. Version bump**: from `~> 0.3.5` to `~> 0.4.0`.

```yaml
- io.oczadly.openrewrite.hcl.ChangeModuleVersion:
    source: "Azure/avm-res-network-privatednszone/azurerm"
    version: "~> 0.3.5"
    newVersion: "~> 0.4.0"
```

**3. Local value conversion**: from `string` to `list` type.

```yaml
- io.oczadly.openrewrite.hcl.ConvertLocalValueInPath:
    source: "Azure/avm-res-network-privatednszone/azurerm"
    version: "~> 0.4.0"
    localName: txt_records
    attributePath: "*.records.*.value"
    transformation: stringToList
```

**4. Input parameter modifications**: removing `resource_group_name` and adding `parent_id`.

```yaml
- io.oczadly.openrewrite.hcl.RemoveModuleInput:
    source: "Azure/avm-res-network-privatednszone/azurerm"
    version: "~> 0.4.0"
    inputName: resource_group_name
- io.oczadly.openrewrite.hcl.AddModuleInput:
    source: "Azure/avm-res-network-privatednszone/azurerm"
    version: "~> 0.4.0"
    inputName: parent_id
    inputValue: "${azurerm_resource_group.avmrg.id}"
```

**5. Resource migration**: three variants for each resource.

```yaml
- io.oczadly.openrewrite.hcl.AddRemovedBlock:
    source: "Azure/avm-res-network-privatednszone/azurerm"
    version: "~> 0.4.0"
    from: module.${avm.pdns.module_name:private_dns_zones}.azurerm_private_dns_zone.this
    lifecycleDestroy: false
- io.oczadly.openrewrite.hcl.AddImportBlock:
    source: "Azure/avm-res-network-privatednszone/azurerm"
    version: "~> 0.4.0"
    to: module.${avm.pdns.module_name:private_dns_zones}.azapi_resource.private_dns_zone
    id: "/subscriptions/${avm.pdns.subscription_id}/resourceGroups/..."
```

This process is repeated for each resource: DNS zones, network links, role assignments, and DNS records (A, AAAA, CNAME, MX, PTR, SRV, TXT).

#### Why so many lines?

The recipe for privatednszone contains approximately 180 lines, mostly repetitions of the same pattern applied to different resources. Is this poor design? No. It is **explicit**, **declarative** list of changes. Each line represents one operation to be performed. During code review, it is immediately clear: _"We are migrating eight DNS record types, each will be removed from state and then imported."_

In practice, when you run `rewriteDryRun`:

```shell
$ ./gradlew rewriteDryRun \
  -Drewrite.activeRecipes=io.oczadly.avm.migrations.res.network.privatednszone.From03xTo04x \
  -Davm.pdns.subscription_id="..." \
  -Davm.pdns.private_dns_zone_name="..."
```

You see the effect: not six copies of the same repetitive block, but specific entries for each resource that exists in your code.

#### Migration result

After applying the YAML recipe, the resulting diff shows:

```diff
diff --git a/projects/avm-res-network-privatednszone/examples/default/main.tf b/projects/avm-res-network-privatednszone/examples/default/main.tf
index 8a17169..132d49a 100644
--- a/projects/avm-res-network-privatednszone/examples/default/main.tf
+++ b/projects/avm-res-network-privatednszone/examples/default/main.tf
@@ -44,10 +44,9 @@ io.oczadly.avm.migrations.res.network.privatednszone.From03xTo04x
 # reference the module and pass in variables as needed
 module "private_dns_zones" {
   source  = "Azure/avm-res-network-privatednszone/azurerm"
-  version = "~> 0.3.5"
+  version = "~> 0.4.0"
 
   domain_name           = local.domain_name
-  resource_group_name   = azurerm_resource_group.avmrg.name
   a_records             = local.a_records
   aaaa_records          = local.aaaa_records
   cname_records         = local.cname_records
@@ -60,4 +59,165 @@
   tags                  = local.tags
   txt_records           = local.txt_records
   virtual_network_links = local.virtual_network_links
+  parent_id             = "${azurerm_resource_group.avmrg.id}"
+}
+
+removed {
+  from = module.private_dns_zones.azurerm_private_dns_zone.this
+  lifecycle {
+    destroy = false
+  }
+}
+
 /* Remaining removed blocks omitted for clarity */
+
+import {
+  to = module.private_dns_zones.azapi_resource.private_dns_zone
+  id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/avmrg/providers/Microsoft.Network/privateDnsZones/testlab.io?api-version=2024-06-01"
+}
+
 /* Remaining import blocks omitted for clarity */

diff --git a/projects/avm-res-network-privatednszone/examples/default/terraform.tf b/projects/avm-res-network-privatednszone/examples/default/terraform.tf
index 712a16f..b92f3b9 100644
--- a/projects/avm-res-network-privatednszone/examples/default/terraform.tf
+++ b/projects/avm-res-network-privatednszone/examples/default/terraform.tf
@@ -7,6 +7,10 @@ io.oczadly.avm.migrations.res.network.privatednszone.From03xTo04x
       source  = "azure/modtm"
       version = "~> 0.3.5"
     }
+    azapi = {
+      source  = "azure/azapi"
+      version = "~> 2.5.0"
+    }
   }

diff --git a/projects/avm-res-network-privatednszone/examples/default/locals.tf b/projects/avm-res-network-privatednszone/examples/default/locals.tf
index 712a16f..b92f3b9 100644
--- a/projects/avm-res-network-privatednszone/examples/default/locals.tf
+++ b/projects/avm-res-network-privatednszone/examples/default/locals.tf
      records = {
        "txtrecordA" = {
-          value = "apple"
+          value = ["apple"]
        }
        "txtrecordB" = {
-          value = "banana"
+          value = ["banana"]
        }
      }
 /* Remaining changes in locals omitted for clarity */
```

As shown above, changes span three files:

1. **main.tf**: module version changes from `~> 0.3.5` to `~> 0.4.0`, the `resource_group_name` parameter is removed, `parent_id` appears, and `removed` and `import` blocks are added for each resource. For clarity, only examples for DNS zones are shown. The pattern repeats identically for `aaaa_record`, `cname_record`, `mx_record`, `ptr_record`, `srv_record`, and `txt_record`.

2. **locals.tf**: text values for DNS records (e.g., `txt_records`) are automatically converted to lists of strings: `"banana"` becomes `["banana"]`. This is necessary because the new module version expects this format.

3. **terraform.tf**: the `azapi` provider is added to the required configuration. This is critical because the new module version uses `azapi_resource` resources instead of Azurerm resources.

[OpenTofu](https://opentofu.org/) / [Terraform](https://developer.hashicorp.com/terraform) in `plan` will show: _"Resource will be imported."_ After `apply`, the resource is re-registered without changing its actual state on Azure.

#### Repeatability

What you do for one Private DNS Zone, you can replicate for ten. The same recipe and parameters always yield the same result. Without scripts, without manual fixes, without the risk of missing something.

At this point, the migration is ready for `rewriteRun` execution and can be approved in the standard code review process as a normal pull request, without additional scripts, exceptions, or manual fixes.

---

## Architecture of the solution

The solution consists of a few clearly separated components:

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

In practice, YAML recipes form a __policy layer__, enabling repeatable, deterministic migrations across one or many projects, regardless of repository layout.

### Gradle

To make these migrations repeatable, I run them through a [Gradle](https://gradle.org/) based workflow. [Gradle](https://gradle.org/) acts as the execution engine: it resolves [OpenRewrite](https://docs.openrewrite.org/) recipes, applies them consistently across repositories, and produces deterministic results that can be validated locally or in CI.

In environments where [Develocity](https://gradle.com/develocity/) is already in use, the same workflow can publish [Build Scans](https://docs.gradle.org/9.0.0/userguide/build_scans.html). This makes it easier to observe execution characteristics and compare results across repositories without requiring any changes to the underlying workflow.

---

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

Additionally, Java recipes are published to [Maven Central](https://central.sonatype.com/artifact/io.oczadly/openrewrite-recipes/overview) via an automated CI/CD pipeline. While publication itself is not a guarantee of quality, it provides verifiable, auditable artifacts with clear provenance and immutability after release.

### Pre-flight validation

Running migrations in `rewriteDryRun` mode, similarly to `tofu plan` / `terraform plan`, allows inspecting the full scope of planned changes without modifying code. This creates space to assess impact, catch unexpected effects, and make informed decisions before applying changes.

---

## Why this scales across organizations

This approach scales not because of the tools involved, but because it addresses the problem at the right level of abstraction. Migrations are treated not as one-off tasks performed manually in individual repositories, but as an explicitly described process that can be reused accross contexts.

Responsibilities are clearly separated:

- Java recipes define **HOW** safe HCL refactoring works.
- YAML recipes define **WHAT** changes in a given migration.
- [Gradle](https://gradle.org/) ensures repeatable execution locally and in CI.

As a result, the same migration can be applied across many repositories, executed by different teams, and integrated into existing CI/CD and code review workflows without requiring a centralized platform.

---

## When this approach does not make sense

This approach is not a universal solution. For small IaC projects consisting of a single module with no planned evolution, the overhead of introducing an additional process may outweigh its benefits.

Similarly, for one-off, trivial changes, such as bumping a version in a single place, tools like [Renovate](https://docs.renovatebot.com/) or even manual edits may be simpler and more appropriate.

The approach also assumes a certain level of organizational maturity: working with pull requests, code review, and treating migrations as part of long-term maintenance rather than incidental fixes.

---

## Summary

Infrastructure as code migrations are inevitable. Module versions change, cloud provider requirements evolve, and best practices shift. The challenge is not the change itself, but **how it is performed**.

This article demonstrated how to approach [OpenTofu](https://opentofu.org/) / [Terraform](https://developer.hashicorp.com/terraform) refactoring in a deterministic, repeatable, and safe way, by using [OpenRewrite](https://docs.openrewrite.org/) as the refactoring engine and [Gradle](https://gradle.org/) as the execution mechanism. Instead of brittle `grep` and `sed` based scripts, the proposed approach relies on explicit recipes, minimal diffs, and pull requests as the sole output of the process.

As a result, migrations stop being risky, one-off events and become a **controlled engineering process** that can be audited, evolved, and safely applied across an organization.

Importantly, the refactoring model presented here is not tied to a single format or tool. Explicit recipes, deterministic execution, and pull requests as the output form a universal approach to safely evolving infrastructure configuration.

{{< admonition example "What's next?" >}}

If you work with AVM or maintain large [OpenTofu](https://opentofu.org/) / [Terraform](https://developer.hashicorp.com/terraform) codebases and are thinking about how to approach migrations safely, this is a model you can try in practice.

👉 Explore the [infra-at-scale/avm-openrewrite-migrations](https://github.com/infra-at-scale/avm-openrewrite-migrations) repository and apply the migrations to your own projects.

If you are interested in extending the refactoring engine or contributing fixes and improvements:

👉 Fork [paweloczadly/openrewrite-recipes](https://github.com/paweloczadly/openrewrite-recipes) and build on top of it.

And if you are dealing with more complex migration scenarios in the [OpenTofu](https://opentofu.org/) / [Terraform](https://developer.hashicorp.com/terraform) ecosystem or across [Kubernetes](https://kubernetes.io/) configurations ([Helm](https://helm.sh/), [Flux](https://fluxcd.io/), [Argo CD](https://argoproj.github.io/cd/)), or want to discuss applying this approach in your organization:

👉 Contact me at [contact@oczadly.io](mailto:contact@oczadly.io).

{{< /admonition >}}

{{< buymeacoffee >}}
