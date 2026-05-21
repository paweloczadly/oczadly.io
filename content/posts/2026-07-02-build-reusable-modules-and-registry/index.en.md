---
title: "Truly reusable IaC modules"
subtitle: "Stable APIs and safe evolution. A complete lifecycle covering testing, versioning, and internal publishing."
series: ["Infrastructure at scale with Azure and OpenTofu"]
code:
  maxShownLines: 70
date: 2026-07-02
description: "Stable APIs and safe evolution. A complete lifecycle covering testing, versioning, and internal publishing."
draft: false
resources:
- name: "featured-image"
  src: "featured-image.png"
---

<!--
Proponowany scope artykułu
1. Problem
Nie wystarczy mieć IaC. Trzeba mieć:
moduły, które da się ponownie używać,
sensowny sposób ich publikacji,
i dystrybucję, która nie rozsypuje się organizacyjnie.
2. Cechy dobrego modułu
Tu wchodzą:
jasno określony kontrakt wejścia/wyjścia,
examples,
docs generation,
versioning,
testowalność,
unikanie nadmiernej logiki lookupów.
Tu bardzo mocno pasuje Twoje:
var + validation zamiast data lookups w module
To jest świetny podpunkt z własną argumentacją.
3. Kiedy własny moduł, a kiedy gotowy
To będzie jeden z najcenniejszych fragmentów.
 Na przykład:
najpierw AVM / gotowy moduł,
własny moduł tylko gdy brakuje sensownej abstrakcji,
unikać „wrapper hell”.
4. Struktura repo modułu
Tu:
examples/
docs generation
tests
template repo
local testing
gha/taskfile
5. Wersjonowanie i publikacja
Tu:
semver
release workflow
internal publishing
discovery/adoption
6. Lightweight internal registry
Tu:
dostępne opcje
dlaczego własne lekkie registry ma sens
Twój przykład: Azure Functions + Storage Account + AAD auth
ewentualnie mirrorowanie jako reliability/control story
7. Podsumowanie
Wniosek:
reusable modules without distribution are not enough,
registry without module discipline is not enough,
oba razem tworzą sensowny model organizacyjny.
-->

Breaking down infrastructure as code and extracting shared patterns into modules is not enough. Just as critical are: structure (contracts, tests, documentation), versioning and publishing (why a registry matters), and adoption without organizational friction.

While working with different clients, I have seen repositories with "modules" that were just wrappers without meaningful abstraction, or where modules were managed like regular resources. That is: no versioning, no tests, no conventions, and no publishing chain. As a result, teams wasted time explaining what a module does, how to update it, and when they could even use it.

Here I will show you the concrete pattern I use: how to design modules that are truly flexible, and how to set up a lightweight registry that does not become additional operational burden.

{{< admonition abstract "About this series" >}}
This article is part of the **"Infrastructure at Scale with Azure and OpenTofu"** series. The full series includes:

- [x] [Azure IaC built for your needs](../2025-09-26-azure-iac-built-for-your-needs/)

  Explore multiple patterns for organizing Infrastructure as Code — their strengths, tradeoffs, and when to use which.
  I will walk you through a proven skeleton that you can adapt in your org or team.

- [ ] [**Truly reusable IaC modules**](#) (you are reading this one now)

  Learn how to design [OpenTofu](https://opentofu.org/) modules with stable APIs, predictable resource identity, practical testing, and safe versioning.
  I will also show you how to build a lightweight module registry you can host anywhere.

- [ ] Secure CI/CD for OpenTofu

  See how a solid CI/CD pipeline can streamline your infrastructure development.
  We will cover tools, automation, and proven patterns to help your code ship faster and safer.

{{< /admonition >}}

## Assumptions

In this article, I am building on the foundation from the [first part](../2025-09-26-azure-iac-built-for-your-needs/) of this series.

I will be using:

* Selected [Azure Verified Modules (AVM)](https://azure.github.io/Azure-Verified-Modules/) conventions and modules where their common language and provider surface is compatible with OpenTofu. [The AVM project officially supports Bicep and Terraform, but not OpenTofu](https://github.com/Azure/Azure-Verified-Modules/discussions/1512), so these examples demonstrate practical compatibility rather than support tested or guaranteed by AVM.
* My own modules and `tofu-registry` implementation where AVM does not provide a suitable abstraction or an example relies on OpenTofu-specific features. The registry will also demonstrate how to build a production-ready, secure, and cost-effective solution without introducing unnecessary operational complexity.

---

## Naming convention

Adding modules to your organization seems easy at first. You create a new repository or directory in your modules monorepo, write some code, deploy, and voilà everything works in production. But time flies. New people join your team, some initial creators leave, and suddenly your modules catalog becomes a mess. That is why it is critical to **establish** a good naming convention early, capture it in an ADR, and automate enforcement of it.

{{< admonition question "AVM naming convention" >}}
One of the things that I appreciate in AVM is their naming convention. Take a look at [it](https://azure.github.io/Azure-Verified-Modules/indexes/terraform/). It categorizes modules into three types: resource, pattern, utility.

It is immediately clear from the module name whether it creates resources, is a pattern, or a utility.

<!--

TODO: 
In my internal registry, I follow the same approach:
- `avm-res-storage-storageaccount` - **resource**: creates a single Azure Storage Account
- `avm-pat-app-authentication` - **pattern**: orchestrates Azure Functions, Key Vault, and managed identity
- `avm-utl-naming` - **utility**: helpers for consistent naming across modules

-->
{{< /admonition >}}

When the same abstraction has implementations for different cloud providers, the module name should identify the provider explicitly. I use the provider's local name rather then inventing another abbreviation, for example `aws`, `azurerm` or `google`.

---

## Repository template

When using repository per module pattern, another good idea is to have a repository template which allows to create modules in a repeatable way. It saves bootstrapping time and makes it easy to switch between different repositories, since the structure is standardized.

A good template repository should include:

* Directory structure: `examples`, `tests` as well as minimal tf files: `locals.tf`, `main.tf`, `outputs.tf`, `terraform.tf`, `variables.tf`.
* CI/CD scaffolding: more in the next article in this series.
* Dependency upgrade manager config: more in the next article in this series.
* `README.md` files for the root module and each example.
* `AGENTS.md` for those who use AI agent support to write or generate code.
* `CHANGELOG.md` for those who prefer not to rely on GitHub releases.

---

## Reusable by design

Before diving into the code, there are several distinguishing characteristics that make a module truly reusable.

Examples are part of a module's public interface. A consumer should be able to find the smallest useful configuration, understand its assumptions, and apply it without reconstructing the required setup. The `default` example from [terraform-azurerm-avm-res-keyvault-vault (v0.10.2)](https://github.com/Azure/terraform-azurerm-avm-res-keyvault-vault/tree/v0.10.2/examples/default) demonstrates this well through a concise README and an end-to-end Terraform configuration.

The root module and each example have their own README generated with [terraform-docs](https://terraform-docs.io/). In the `default` example, the generated documentation includes the complete calling configuration together with its provider requirements, inputs, outputs, and module dependencies.

Generating documentation from the same configuration reduces manual duplication and keeps the example's reference material synchronized with its source. It does not, however, prove that the configuration can be initialized, planned, or applied. The examples become executable contracts only when they are verified as part of the strategy described later in [Testing](#testing).

Good examples should be:

- [x] Focused on one use case
- [x] Readable and well documented
- [x] Ready to initialize, plan, and apply

Another critical characteristic is the migration path between module versions. A good IaC module should include:

- [x] Release notes
- [x] Breaking changes
- [x] Migration path (upgrade + rollback)

The release notes of [terraform-azurerm-avm-res-network-privatednszone (v0.4.0)](https://github.com/Azure/terraform-azurerm-avm-res-network-privatednszone/releases/tag/v0.4.0) demonstrate this well. They clearly document all three items, which I find essential. With this information, planning migrations becomes straightforward, and you can create [OpenRewrite](https://docs.openrewrite.org/) recipes or build custom automation.

{{< admonition question "Organization-wide refactoring" >}}
Planning the migration path is one thing. Executing it deterministically across many repositories is another. In my previous article, [Refactoring HCL organization-wide with OpenRewrite](../2026-04-23-refactoring-hcl-organization-wide-with-openrewrite/), I showed how to approach infrastructure-as-code refactoring in a repeatable, auditable way using [OpenRewrite](https://docs.openrewrite.org/) recipes.

If you are working with multiple module repositories or coordinating migrations across teams, that approach transforms ad hoc scripts into controlled processes that land as clean pull requests.
{{< /admonition >}}

Reusability should be demonstrated, not merely claimed. Tests document expected behavior, expose breaking changes before release, and give consumers evidence that the module can evolve without destabilizing their deployments. The [Testing](#testing) section shows how to build that evidence incrementally, from fast contract checks to executable examples and real deployments.

These signals give consumers confidence to adopt a module. Its implementation must uphold that promise: the module should remain focused, make its dependencies explicit, and offer flexibility without attempting to support every possible configuration.

---

## Implementation

There is no universal measure of how configurable a module should be. Too few options make it little more than a rigid wrapper, whereas too many turn its interface into another provider schema that is harder to understand and maintain than the resources underneath it.

The goal is to expose the decisions consumers genuinely need to make while keeping the module's responsibility and contract clear.

A module should represent an intentional abstraction, not merely relocate resource declarations into another repository. The [Azure Well-Architected Framework](https://learn.microsoft.com/en-us/azure/well-architected/operational-excellence/infrastructure-as-code-design) recommends using modules to encapsulate complex configurations or meaningful combinations of resources, while avoiding unnecessary abstraction when a resource's default configuration is already sufficient.

### Organize resources by responsibility

Once the module's responsibility is clear, its resource graph should make that responsibility easy to recognize.

[OpenTofu](https://opentofu.org/) evaluates all configuration files in a module as a single configuration. Splitting resources across files does not affect dependency resolution or deployment order. That separation exists entirely for the benefit of readers and maintainers.

For small modules, keeping resources together in `main.tf` is often the most readable option. As a module grows, however, a single file can obscure the architecture it is supposed to express. At that point, I split the configuration by responsibility, using consistent file names across provider-specific implementations wherever the underlying concepts align, for example `main-compute.tf`, `main-database.tf`, `main-dns.tf`, `main-object-storage.tf`.

### Preserve resource identity across changes

OpenTofu associates every managed object in its state with a resource address. Within a module, that address consists of the resource type and its local name. The calling configuration prefixes it with the path of the module instance, for example: `module.tofu_registry.azurerm_storage_account.registry`.

File names are not part of a resource address. Moving a resource block from `main.tf` to `main-object-storage.tf` changes only the organization of the source code. Renaming the block itself, however, changes its address and can cause OpenTofu to plan the destruction of the object at the old address and the creation of another at the new one.

The `count` and `for_each` meta-arguments extend resource addresses with instance keys and introduce additional identity considerations. They are discussed separately in the next section.

#### Rename a resource without replacing it

Suppose an earlier version of the module declared its storage account as follows.

**`main-object-storage.tf`:**

```hcl
resource "azurerm_storage_account" "artifacts" {
  /* Remaining code omitted for clarity */
}
```

A later version might use a name that better describes the resource's role.

**`main-object-storage.tf`:**

```hcl
resource "azurerm_storage_account" "registry" {
  /* Remaining code omitted for clarity */
}
```

Without an explicit migration, the old and new addresses are unrelated from OpenTofu's perspective. A `moved` block records that both addresses represent the same managed object:

**`moved.tf`:**

```hcl
moved {
  from = azurerm_storage_account.artifacts
  to   = azurerm_storage_account.registry
}
```

When a consumer upgrades the module, OpenTofu associates the existing state object with the new address before calculating the remaining changes. The migration travels with the module and does not require consumers to run `tofu state mv` in every workspace.

#### Move a resource to a child module

The same mechanism supports more advanced refactorings, including moving a resource into a local child module distributed as part of the same module package.

**`modules/storage/main.tf`:**

```hcl
resource "azurerm_storage_account" "registry" {
  /* Remaining code omitted for clarity */
}
```

**`main-object-storage.tf`:**

```hcl
module "storage" {
  source = "./modules/storage"

  /* Remaining code omitted for clarity */
}
```

**`moved.tf`:**

```hcl
moved {
  from = azurerm_storage_account.registry
  to   = module.storage.azurerm_storage_account.registry
}
```

When a consumer upgrades, OpenTofu associates the existing state object with the resource inside the child module instead of planning to recreate it. This pattern is appropriate when the parent and child modules are maintained and distributed together.

However, a module can declare moves only for its own objects and objects in its child modules. It cannot rewrite addresses belonging to its caller or an unrelated module.

#### Preserve upgrade paths across multiple renames

Consumers of a truly reusable module do not necessarily install every release. One deployment might upgrade from the immediately preceding version, while another might skip several versions.

Suppose the same resource had the following names over its lifetime:

1. `azurerm_storage_account.storage`
2. `azurerm_storage_account.artifacts`
3. `azurerm_storage_account.registry`

Preserve the complete history as a chain of migrations:

**`moved.tf`:**

```hcl
moved {
  from = azurerm_storage_account.storage
  to   = azurerm_storage_account.artifacts
}

moved {
  from = azurerm_storage_account.artifacts
  to   = azurerm_storage_account.registry
}
```

This allows consumers using either historical address to upgrade directly to the current module version. Removing an old `moved` block can therefore be a breaking change, even when all consumers of the most recent release have already applied the newer address.

Before publishing a refactoring release, test the upgrade against state created with an earlier supported module version. The resulting plan should show the address migration without any unexpected destroy-and-create actions.

### Use `enabled`, `count`, and `for_each` deliberately

Optional behavior is sometimes necessary, but every conditional branch multiplies the number of module configurations that must be understood, tested, and supported.

The `enabled`, `count`, and `for_each` meta-arguments do more than reduce repetition. They determine whether a resource has no instance key, an integer key, or a string key. Choosing between them is therefore a decision about resource identity, not merely syntax:

- Use [`enabled`](https://opentofu.org/docs/v1.12/language/meta-arguments/enabled/) for an optional singleton.
- Use [`count`](https://opentofu.org/docs/v1.12/language/meta-arguments/count/) when an ordinal position is the intended identity.
- Use [`for_each`](https://opentofu.org/docs/v1.12/language/meta-arguments/for_each/) when every instance has a stable, meaningful key.

#### Model an optional singleton with `enabled`

OpenTofu provides the `enabled` lifecycle meta-argument for a resource or module that may have either zero or one instance. Unlike the traditional `count = condition ? 1 : 0` pattern, it preserves the unkeyed resource address and does not force consumers to access an otherwise singular resource through `[0]`.

**`variables.tf`:**

```hcl
variable "create_dns_record" {
  description = "Whether to create a private DNS record for the registry."
  type        = bool
  default     = true
}
```

**`main-dns.tf`:**

```hcl
resource "azurerm_private_dns_cname_record" "this" {
  name                = var.dns_record_name
  zone_name           = var.private_dns_zone_name
  resource_group_name = azurerm_resource_group.this.name
  ttl                 = 300
  record              = azurerm_storage_account.registry.primary_blob_host

  lifecycle {
    enabled = var.create_dns_record
  }
}
```

**`outputs.tf`:**

```hcl
output "dns_record_fqdn" {
  description = "The FQDN of the registry DNS record, or null when it is disabled."
  value = (
    azurerm_private_dns_cname_record.this != null
    ? azurerm_private_dns_cname_record.this.fqdn
    : null
  )
}
```

When disabled, the resource evaluates to `null`. Consumers can therefore reason about an optional object directly rather than treating it as a collection that happens to contain at most one element.

The `enabled` meta-argument was introduced in [OpenTofu 1.11.0](https://opentofu.org/docs/v1.11/language/meta-arguments/enabled/). Using it makes that minimum OpenTofu version part of the module contract and should be reflected in its version constraint.

#### Use `count` only when position is identity

The `count` meta-argument is appropriate for a homogeneous, numbered pool where instances are intentionally identified by their ordinal position.

For example, a module can create a configurable number of outbound public IP addresses.

**`variables.tf`:**

```hcl
variable "outbound_public_ip_count" {
  description = "Number of outbound public IP addresses to create."
  type        = number
  default     = 1

  validation {
    condition = (
      var.outbound_public_ip_count >= 0
      && floor(var.outbound_public_ip_count) == var.outbound_public_ip_count
    )
    error_message = "outbound_public_ip_count must be a non-negative integer."
  }
}
```

**`main-network.tf`:**

```hcl
resource "azurerm_public_ip" "outbound" {
  count = var.outbound_public_ip_count

  name = format(
    "%s-outbound-%02d",
    local.name,
    count.index + 1,
  )

  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location
  allocation_method   = "Static"
}
```

Increasing `count` appends new instance addresses. Decreasing `count` removes the instances with the highest indexes. This is predictable as long as the pool is managed only by its size.

Do not derive `count` from a list of independently managed objects. Removing an element from the middle of such a list associates every subsequent index with a different object and can produce unrelated updates or replacements.

#### Give independent instances stable keys

Use `for_each` when callers need to add, remove, or modify independently managed objects. Its keys become part of the resource addresses and should represent stable identities rather than mutable configuration values.

**`variables.tf`:**

```hcl
variable "storage_containers" {
  description = "Storage containers managed by the registry."
  type = map(object({
    name                  = string
    container_access_type = optional(string, "private")
  }))
}
```

A caller can separate the stable logical identity from the provider-facing name:

```hcl
storage_containers = {
  modules = {
    name = "module-packages"
  }
  providers = {
    name = "provider-packages"
  }
}
```

**`main-object-storage.tf`:**

```hcl
resource "azurerm_storage_container" "registry" {
  for_each = var.storage_containers

  name                  = each.value.name
  container_access_type = each.value.container_access_type
  storage_account_id    = azurerm_storage_account.registry.id
}
```

The resulting addresses are stable and meaningful:

```text
azurerm_storage_container.registry["modules"]
azurerm_storage_container.registry["providers"]
```

Adding another key creates one instance, while removing a key destroys only the corresponding instance. Renaming a key changes its address and requires a `moved` block when the old and new keys represent the same remote object.

The complete set of keys must be known during planning. Keep values that may remain unknown until apply inside the map values rather than using them to construct its keys.

Repetition should not become a substitute for a clear module contract. Avoid exposing a separate boolean for every resource when several resources together represent one capability. Derive one readable condition and apply it consistently to the related resource blocks.

Test not only the individual configurations but also transitions between them:

- From `enabled = false` to `true` and back.
- Increasing and decreasing `count`.
- Adding and removing `for_each` keys.
- Renaming a key through a `moved` block.

These transitions are where unintended changes to resource identity become visible. Choose `enabled`, `count`, or `for_each` based on the identity model and expected lifecycle of the instances, not on perceived performance differences between the meta-arguments.

### Treat variables as an API

Input variables form the public API of a module. Once consumers depend on them, their names, types, defaults, validation rules, and nullability become compatibility decisions. A truly reusable module should therefore expose the choices its consumers genuinely need to make, rather than mirror every argument supported by the underlying provider. As with any well-designed API, the module's public surface should remain as small and stable as practical.

Keeping that surface small also has a practical benefit: each input expands the module's testing surface and transfers a decision to its consumers. Before adding one, I ask whether callers need to control the value, whether the module can provide a sensible policy instead, and whether I am prepared to support that input across future versions.

#### Distinguish required decisions from sensible defaults

Required inputs should represent decisions the module cannot make responsibly. Giving such inputs arbitrary defaults may make the module easier to call, but it can also hide important architectural choices.

```hcl
variable "location" {
  description = "Azure region in which the resources will be created."
  type        = string
  nullable    = false

  validation {
    condition     = trimspace(var.location) != ""
    error_message = "The location must not be empty."
  }
}

variable "tags" {
  description = "Additional tags to apply to all resources created by the module."
  type        = map(string)
  default     = {}
  nullable    = false
}
```

The module should not silently choose an Azure region because location affects latency, availability, compliance, and cost. An empty map, however, is a natural default for additional tags.

Defaults are part of the module's behavior, not merely a convenience. Changing one may alter an existing consumer's plan without any change to its configuration. Such changes should therefore be reviewed and released with the same care as changes to resource arguments.

#### Group settings that belong together

Related settings can be represented as a typed object. This keeps the module interface cohesive and makes the relationship between individual options explicit.

```hcl
variable "database" {
  description = "Configuration of the PostgreSQL Flexible Server."
  type = object({
    sku_name              = optional(string)
    storage_mb            = optional(number)
    backup_retention_days = optional(number, 7)
  })
  default  = {}
  nullable = false

  validation {
    condition = (
      var.database.backup_retention_days >= 7
      && var.database.backup_retention_days <= 35
    )
    error_message = "The backup retention period must be between 7 and 35 days."
  }
}
```

A typed object documents the expected shape and allows the module to add optional attributes without introducing an unrelated top-level variable for every setting. Validation also catches invalid configurations at the module boundary, before the provider attempts to create or update a resource.

An object should still represent a coherent capability. One large `settings` object containing every provider argument merely reproduces the provider schema under another name. The module then becomes a thin, harder-to-use proxy rather than a meaningful abstraction.

For the same reason, I avoid `any` unless the module treats a value as opaque and passes it to another system without inspecting its structure. Explicit types produce better diagnostics, clearer documentation, and a more predictable contract. OpenTofu also notes that [any](https://opentofu.org/docs/v1.12/language/expressions/type-constraints/#dynamic-types-the-any-constraint) is rarely the correct type constraint.

#### Deprecate inputs before removing them

Renaming or restructuring an input is an API migration. When possible, the module should keep the old input available for a transition period and provide clear instructions for migrating to its replacement.

```hcl
variable "database_sku_name" {
  description = "Deprecated: use database.sku_name instead."
  type        = string
  default     = null

  deprecated = "Use database.sku_name instead. This input will be removed in v2.0.0."
}
```

Deprecation alone does not preserve compatibility. During the migration period, the module must continue to honor the old input, define what happens when both forms are supplied, and test the chosen precedence. The normalization layer can then translate both versions of the public contract into one internal representation.

Removing an input, adding a new required input, narrowing its accepted type, or changing the meaning of an existing value should normally be treated as a breaking change. Adding an optional input is usually backward-compatible, although its interaction with existing defaults and resources must still be considered.

#### Distinguish sensitive from ephemeral values

Marking a variable as `sensitive` prevents OpenTofu from displaying its value in normal CLI output, but does not prevent that value from being stored in the plan or state.

```hcl
variable "database_admin_password" {
  description = "Password of the PostgreSQL server administrator."
  type        = string
  sensitive   = true
  nullable    = false
}
```

The state must therefore still be treated as sensitive data and protected through encryption, access control, and an appropriate retention policy.

An ephemeral variable provides a stronger but more restrictive guarantee.

```hcl
variable "access_token" {
  description = "Short-lived token used to authenticate with an external service."
  type        = string
  sensitive   = true
  ephemeral   = true
  nullable    = false
}
```

OpenTofu does not store ephemeral values in the plan or state. However, an ephemeral value may flow only into a supported ephemeral context, such as an ephemeral resource, an ephemeral output, a provider configuration, a provisioner, a connection block, or a resource's write-only attribute.

This means that `ephemeral` is not a drop-in replacement for `sensitive`. For example, a password cannot be marked as ephemeral and then assigned to a regular resource argument that OpenTofu must persist in state. The provider must expose a compatible write-only argument, or the value must be consumed through another supported ephemeral context.

Whether an input is ephemeral is therefore part of the module's API contract. It affects not only how OpenTofu stores the value but also how callers can pass it through their own modules and outputs. Use it for genuinely transient data with a complete ephemeral path, rather than as a general-purpose marker for every secret.

For the complete list of supported contexts, see the OpenTofu documentation on [ephemeral variables](https://opentofu.org/docs/v1.12/language/values/variables/#ephemerality).

A well-designed variable interface exposes the decisions consumers own while keeping provider-specific representations and module policy behind the boundary. Once that contract is explicit, the module can normalize it into the structures required by its resources.

### Normalize inputs at the module boundary

Variables define what consumers can provide, but their shape does not always need to match the provider schema exactly. I use local values as a translation layer between the module's public contract and its resource implementation.

This is useful for deriving resource names, merging tags, resolving optional settings, and transforming collections into stable maps for `for_each`. Keeping these transformations in one place also prevents the same expressions from being repeated across multiple resources.

The flow should remain easy to follow: validate inputs, normalize them once, and let resources consume the normalized representation. Locals should simplify the resource graph, not become a hidden configuration engine.

#### Normalize optionals

Optional attributes make a module easier to consume, but resources should not need to handle missing values independently. I normalize optional inputs into a complete internal representation by applying defaults in local values. This keeps fallback logic at the module boundary and lets resources consume predictable values.

**`variables.tf`:**

```hcl
variable "database" {
  type = object({
    sku_name   = optional(string)
    storage_mb = optional(number)
  })
  default  = {}
  nullable = false

  /* Remaining code omitted for clarity */
}
```

**`locals.tf`:**

```hcl
locals {
  database = {
    sku_name   = coalesce(var.database.sku_name, "B_Standard_B1ms")
    storage_mb = coalesce(var.database.storage_mb, 32768)
  }
}
```

**`main.tf`:**

```hcl
resource "azurerm_postgresql_flexible_server" "registry" {
  sku_name   = local.database.sku_name
  storage_mb = local.database.storage_mb

  /* Remaining code omitted for clarity */
}
```

#### Normalize lists into keyed maps

When a list represents independently managed objects, I often normalize it into a map before using it with `for_each`. The map key should describe the stable identity of an object rather than its position in the input list.

**`variables.tf`:**

```hcl
variable "dns_records" {
  type = list(object({
    name  = string
    type  = string
    value = string
  }))

  /* Remaining code omitted for clarity */
}
```

**`locals.tf`:**

```hcl
locals {
  dns_records_by_name = {
    for record in var.dns_records :
    "${record.type}:${record.name}" => record
  }
}
```

**`main.tf`:**

```hcl
resource "example_dns_record" "this" {
  for_each = local.dns_records_by_name

  name  = each.value.name
  type  = each.value.type
  value = each.value.value
}
```

#### Merge tags with explicit precedence

Modules often need to combine standard tags with tags provided by their consumers. I merge both maps in a local value and define their order so that consumer-provided tags take precedence when the same key exists in both maps. Because this precedence is part of the module's behavior, it should be intentional and documented.

**`locals.tf`:**

```hcl
locals {
  default_tags = {
    managed_by = "opentofu"
    component  = "tofu-registry"
  }

  tags = merge(local.default_tags, var.tags)
}
```

Local values should translate an explicit contract, not compensate for implicit dependencies. Once inputs are normalized, the remaining question is whether the module or its caller should resolve the external values it needs.

### Pass dependencies, do not discover them

Whenever possible, I resolve external dependencies outside a module and pass only the values it needs through input variables. A module should declare what it requires, while leaving the caller responsible for deciding where those values come from.

This is an application of **dependency inversion**. The module depends on a stable contract rather than on a particular lookup mechanism, naming convention, resource group, or tagging strategy. The caller can satisfy that contract with a managed resource, a data source, another module's output, remote state, or a value supplied by the surrounding platform.

OpenTofu recommends this approach in its documentation on [module composition](https://opentofu.org/docs/v1.12/language/modules/develop/composition/#dependency-inversion). Keeping the module tree relatively flat and composing modules in the caller makes relationships between infrastructure components easier to see and change.

#### Resolve lookups in the caller

Where a dependency is resolved determines more than how its value is obtained. It can also determine which subscription, tenant, and provider configuration must be available. Resolving external dependencies in the caller keeps that topology at the composition layer instead of making it part of every reusable module's contract.

[terraform-azurerm-avm-res-web-site](https://github.com/Azure/terraform-azurerm-avm-res-web-site/tree/v0.22.0) demonstrates this separation particularly well. It accepts resolved values such as an App Service Plan resource ID, a virtual network subnet ID, an Application Insights connection string, and a Log Analytics workspace resource ID. Its implementation does not require the [azurerm provider](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs) merely to discover those dependencies.

Consider a Function App deployed in a workload subscription but integrated with a subnet managed in a central connectivity subscription. Azure supports this topology as long as the required provider registration and permissions are in place. The caller can select the appropriate provider configuration, perform the lookup, and pass the resulting ID to the module.

**`providers.tf`:**

```hcl
provider "azapi" {
  subscription_id = var.workload_subscription_id
}

provider "azurerm" {
  alias           = "connectivity"
  subscription_id = var.connectivity_subscription_id

  features {}
}
```

**`data.tf`:**

```hcl
data "azurerm_subnet" "function_app" {
  provider = azurerm.connectivity

  name                 = "snet-functions"
  resource_group_name  = "rg-connectivity-production"
  virtual_network_name = "vnet-production"
}
```

**`main.tf`:**

```hcl
module "function_app" {
  source  = "Azure/avm-res-web-site/azurerm"
  version = "0.22.0"

  # Required:
  location                 = "westeurope"
  name                     = "func-tofu-registry"
  parent_id                = azapi_resource.resource_group.id
  service_plan_resource_id = module.app_service_plan.resource_id

  # Optional:
  virtual_network_subnet_id = data.azurerm_subnet.function_app.id

  /* Remaining code omitted for clarity */
}
```

Azure explicitly permits App Service virtual network integration with a subnet in another subscription. This makes the example architecturally realistic rather than artificial. Microsoft documents the requirements for this topology in its [App Service virtual network integration guidance](https://learn.microsoft.com/en-us/azure/app-service/configure-vnet-integration-enable).

A truly reusable module does not need to know that the subnet belongs to the connectivity subscription, how authentication for that subscription is configured, or whether the value came from a data source at all. A caller could later replace the lookup with another module's output or a value supplied by a platform service without changing the Function App module.

If the lookup were moved into the child module, the module would need access to a provider configuration targeting the connectivity subscription. Whether implemented through an additional [azapi provider](https://registry.terraform.io/providers/Azure/azapi/latest/docs) alias or a new `azurerm` requirement, every caller would have to understand and supply that topology. Passing the resolved subnet ID keeps this responsibility at the composition layer.

#### Keep dependency contracts narrow

Pass only the attributes the module actually consumes. If a resource needs only an identifier, accept a string containing that identifier. If several attributes describe one coherent dependency, group them in a typed object.

Avoid accepting lookup criteria merely to reconstruct the value internally:

```hcl
variable "subnet_tags" {
  type = map(string)
}
```

Tags are a discovery policy, not the dependency itself. They may match more than one object, change independently of the module, or require permissions that some callers do not otherwise need. Prefer accepting the resolved value:

```hcl
variable "subnet_id" {
  description = "ID of the subnet used by the private endpoint."
  type        = string
  nullable    = false
}
```

This keeps the module independent of resource naming and ownership conventions. It also makes tests easier because callers can supply the dependency contract directly without recreating the production discovery mechanism.

Explicit dependencies improve refactoring as well. A resource managed in the same configuration can later be replaced with a data source, another module output, or a value from remote state without changing the reusable module's interface.

#### Keep a lookup only when it is the abstraction

A lookup belongs inside a module when resolving the value is itself the capability the module provides.

A data-only module can, for example, encapsulate how applications join a shared organizational network:

```hcl
module "shared_network" {
  source  = "infra-at-scale/org-shared-network/azurerm"
  version = "1.0.0"

  environment = "production"
}

module "application" {
  source  = "infra-at-scale/svc-checkout/azurerm"
  version = "1.0.0"

  subnet_id = module.shared_network.apps_subnet_id
}
```

The data-only module may resolve the network through provider data sources, remote state, or an internal service. Its abstraction is valuable because callers depend on a stable organizational concept rather than on the current storage or lookup mechanism.

This exception should remain deliberate. A data source does not become part of an abstraction merely because placing it inside the module is convenient. The lookup should hide a meaningful policy or integration boundary that the module explicitly owns. OpenTofu describes this pattern in its guidance on [data-only modules](https://opentofu.org/docs/v1.12/language/modules/develop/composition/#data-only-modules).

Do not use `depends_on` to compensate for a lookup that hides ownership. Applying it to an entire module creates a broader and more conservative dependency than passing the specific resource attribute that the consumer needs. Keep a lookup inside the child only when discovery itself is part of the abstraction the module deliberately owns.

Inputs allow a module to receive dependencies, while outputs allow it to become one.

### Design outputs for composition

Outputs are not merely values printed after an apply. They are the composition points through which other modules depend on the infrastructure this module manages.

Each output extends the module's public API. I expose values that identify the managed object, allow another component to connect to it, or establish a meaningful dependency. The [terraform-azurerm-avm-res-web-site](https://github.com/Azure/terraform-azurerm-avm-res-web-site/blob/v0.22.0/outputs.tf) module demonstrates this well. Alongside its complete `resource` output, it provides dedicated outputs such as `resource_id`, `resource_uri`, and `system_assigned_mi_principal_id`.

This gives callers stable composition points for role assignments, DNS records, monitoring, and other modules without requiring them to understand the underlying `azapi_resource`. The complete resource object remains available for advanced use cases, but consumers do not need to depend on its internal shape for common operations.

Avoid making an entire provider resource object the module's only supported interface. Its inferred shape follows the provider or underlying module and encourages callers to depend on incidental attributes. Even when exposing the complete object as a convenience, provide dedicated outputs for the stable values that consumers commonly need. Group several values in an object only when they describe one coherent concept and are expected to evolve together.

Output names, value types, sensitivity, and whether a value can become `null` are compatibility decisions. Renaming or removing an output, or changing a string into an object, can break every caller that references it. Adding an output is normally backward-compatible. If an output must be replaced, mark it as `deprecated`, provide migration instructions, and preserve its previous behavior for a documented migration period.

Use output preconditions for guarantees the module promises to its consumers, just as variable validation checks assumptions about its inputs. Mark confidential values as `sensitive`, but remember that this only redacts them from normal CLI output, even though OpenTofu still stores sensitive root outputs in state. Sensitivity also propagates through references. Because the AVM Web Site module marks its resource ID and identity outputs as sensitive, a caller that re-exports them must preserve that metadata or deliberately remove it after reviewing the risk.

For transient secrets, OpenTofu supports `ephemeral` child outputs, which are omitted from plan and state and can be consumed only in ephemeral contexts. Resource IDs, endpoints, and principal IDs are regular composition values and should not be ephemeral.

Outputs define the values a module exposes to its callers. Provider requirements define the external APIs it needs without taking ownership of how access to them is configured.

### Declare provider requirements, not configurations

A truly reusable module should declare which providers it requires without deciding how those providers authenticate or which subscription, tenant, or endpoint they target. These are separate contracts. A provider requirement identifies a plugin and the range of versions compatible with the module. A provider configuration supplies credentials and runtime settings. Every module owns the former. By contrast, only the composition root should own the latter.

Declare each provider used directly by the module with an explicit source address and a compatibility constraint.

**`terraform.tf`:**

```hcl
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 4.0.0, < 5.0.0"
    }

    azapi = {
      source  = "Azure/azapi"
      version = ">= 2.9.0, < 3.0.0"
    }
  }
}
```

Do not add providers merely because callers may use them to resolve inputs. For example, a module that accepts a subnet resource ID but declares no resources or data sources from the `azurerm` provider does not require it. This keeps its dependency surface aligned with what its implementation actually uses.

The lower version bound should identify the earliest provider release that contains every feature on which the module depends. The upper bound is a deliberate policy choice. The [OpenTofu documentation](https://opentofu.org/docs/v1.12/language/modules/develop/providers/#provider-version-constraints-in-modules) recommends specifying only a minimum version in child modules, leaving the root module responsible for restricting upgrades. [AVM specification TFNFR26](https://azure.github.io/Azure-Verified-Modules/spec/TFNFR26/) instead requires both a minimum version and a maximum major version.

For organization-owned modules, I prefer the AVM approach. It prevents consumers from silently selecting an untested major release, but it also creates a maintenance obligation: every new major version must be tested before the constraint can be widened. In either case, a compatibility constraint does not select an exact provider release. The root module resolves one version that satisfies all module constraints and records that selection in its dependency lock file.

OpenTofu compatibility should be declared just as deliberately. OpenTofu 1.12 introduces the [`language` block](https://opentofu.org/docs/v1.12/language/settings/), which allows an OpenTofu-first module to state its implementation requirement explicitly:

**`versions.tofu`:**

```hcl
language {
  compatible_with {
    opentofu = ">= 1.12.0"
  }
}
```

The minimum version should reflect the language features the module actually uses, not whichever OpenTofu release happens to be installed on the author's workstation. A module that must also support Terraform can pair `versions.tofu` with a `versions.tf` file containing Terraform's `required_version`. When both files are present, OpenTofu gives `versions.tofu` precedence over `versions.tf`, while Terraform ignores the `.tofu` file. AVM modules use Terraform's `required_version` because AVM officially targets Terraform rather than OpenTofu.

Provider configurations then remain in the root module:

**`providers.tf`:**

```hcl
provider "azapi" {
  alias = "workload"

  subscription_id = var.workload_subscription_id
}
```

**`main.tf`:**

```hcl
module "application" {
  source = "./modules/application"

  providers = {
    azapi = azapi.workload
  }
}
```

The child knows that it requires `Azure/azapi`, but it does not know how authentication is established or that the caller names this configuration `workload`. The mapping translates the provider name expected by the child into a configuration selected by the caller. When the default configuration is sufficient, OpenTofu can inherit it implicitly. An explicit mapping is useful when the target subscription should remain visible at the composition layer.

Use `configuration_aliases` only when distinct provider configurations are intrinsic to the abstraction. Deploying resources into different subscriptions does not necessarily meet that condition. If the same identity can access both scopes and the provider operation accepts complete resource IDs, passing those IDs may be sufficient.

The [terraform-azurerm-avm-res-network-virtualnetwork](https://github.com/Azure/terraform-azurerm-avm-res-network-virtualnetwork/tree/v0.19.0) module demonstrates this approach. It can create both directions of a virtual network peering, including a reverse peering whose parent is identified by [`remote_virtual_network_resource_id`](https://github.com/Azure/terraform-azurerm-avm-res-network-virtualnetwork/blob/v0.19.0/modules/peering/main.tf#L39). Both resources use a single AzAPI provider configuration, so no provider alias is required merely because the virtual networks may belong to different subscriptions.

Prefer this model or compose two independently scoped module calls in the root whenever ownership can be separated cleanly. Both approaches keep authentication topology out of the child module's public API.

A configuration alias becomes justified when passing an ID cannot supply the execution context required by the provider. For example, a module that deliberately owns both sides of a cross-tenant relationship may need one provider configuration authenticated against the local tenant and another authenticated against the remote tenant:

```hcl
terraform {
  required_providers {
    azapi = {
      source                = "Azure/azapi"
      version               = ">= 2.9.0, < 3.0.0"
      configuration_aliases = [azapi.remote]
    }
  }
}
```

The caller must then supply both execution contexts:

```hcl
module "cross_tenant_peering" {
  source = "./modules/cross-tenant-peering"

  providers = {
    azapi        = azapi.local
    azapi.remote = azapi.remote
  }

  local_virtual_network_id  = var.local_virtual_network_id
  remote_virtual_network_id = var.remote_virtual_network_id
}
```

This should remain an exception. Before adding a provider alias, consider whether the abstraction can be divided into two module calls, each receiving one provider configuration and exchanging resource IDs through the caller.

Never place a `provider` block inside a reusable module. Besides taking ownership of credentials and deployment scope, a local provider configuration makes the module incompatible with module-level `count`, `for_each`, `depends_on`, and, in OpenTofu 1.12, `enabled`. This is why both the [OpenTofu documentation](https://opentofu.org/docs/v1.12/language/modules/develop/providers/) and [AVM specification TFNFR27](https://azure.github.io/Azure-Verified-Modules/spec/TFNFR27/) require provider configurations to remain outside modules.

Provider requirements describe the compatibility a module claims. Testing determines whether that claim remains true as OpenTofu, providers, and the module itself evolve.

---

## Testing

A module that applies once is not necessarily safe to reuse. Its contract includes accepted inputs, generated resource configuration, outputs, runtime behavior, idempotency, and the ability to upgrade existing deployments without unexpected replacements.

Testing should provide evidence for each of these properties at the cheapest layer capable of observing it. Fast tests can cover a broad input surface, while a smaller number of deployment tests verify the assumptions that require a real provider and the Azure control plane.

This layered approach also appears in the [Azure Verified Modules specifications](https://azure.github.io/Azure-Verified-Modules/specs/tf/res/#testing). AVM requires static analysis, end-to-end deployment tests, and idempotency tests, while recommending unit and upgrade tests. The exact tooling may differ for an OpenTofu-first module, but the underlying principle remains useful: no single test type can validate the entire module contract.

### Test the contract without deploying

Formatting and validation are the first line of defense. Every module and its examples should pass `tofu fmt -check` and `tofu validate`. Linters and policy scanners can add organization-specific rules, but these checks still prove only that the configuration is syntactically and structurally acceptable. They do not verify how input combinations affect the resulting resource graph.

Not every invalid configuration should have to reach a provider operation before it is rejected. When the module can determine from its inputs that a configuration is invalid, the corresponding rule should become part of its executable contract. Use variable validation for constraints that belong to an input and preconditions for assumptions that span multiple values.

This allows the module to fail fast with domain-specific feedback during `tofu plan` whenever the required values are already known. Instead of receiving a provider error later during planning or after an API operation has been attempted, the caller learns which assumption was violated at the module boundary. OpenTofu evaluates [custom conditions](https://opentofu.org/docs/v1.12/language/expressions/custom-conditions/) as early as their values allow. A condition based on values known during planning can stop the plan, while one that depends on values known only after resource creation must be deferred until apply.

Validation rules are not a substitute for tests. They are production behavior and can themselves be incomplete, overly restrictive, or accidentally changed. A validation rule should therefore be tested with accepted boundary values and representative failures.

OpenTofu's native [testing framework](https://opentofu.org/docs/v1.12/cli/commands/test/) can exercise variable validation, defaults, conditional resources, normalized values, outputs, preconditions, and postconditions. A test can use `command = plan` together with a mock provider when the behavior being verified does not require Azure.

For example, the module can verify its default database policy and reject retention periods outside the supported range.

**`tests/database.tofutest.hcl`:**

```hcl
mock_provider "azurerm" {}

variables {
  location = "westeurope"

  /* Remaining code omitted for clarity */
}

run "use_database_defaults" {
  command = plan

  assert {
    condition     = azurerm_postgresql_flexible_server.registry.sku_name == "B_Standard_B1ms"
    error_message = "The module should use its default database SKU."
  }

  assert {
    condition     = azurerm_postgresql_flexible_server.registry.storage_mb == 32768
    error_message = "The module should use its default database storage size."
  }

  assert {
    condition     = azurerm_postgresql_flexible_server.registry.backup_retention_days == 7
    error_message = "The module should use a seven-day backup retention period by default."
  }
}

run "reject_backup_retention_below_minimum" {
  command = plan

  variables {
    database = {
      backup_retention_days = 6
    }
  }

  expect_failures = [
    var.database,
  ]
}

run "accept_maximum_backup_retention" {
  command = plan

  variables {
    database = {
      backup_retention_days = 35
    }
  }

  assert {
    condition     = azurerm_postgresql_flexible_server.registry.backup_retention_days == 35
    error_message = "The module should accept a 35-day backup retention period."
  }
}

run "reject_backup_retention_above_maximum" {
  command = plan

  variables {
    database = {
      backup_retention_days = 36
    }
  }

  expect_failures = [
    var.database,
  ]
}
```

The first run confirms that the defaults form an accepted configuration and are propagated to the resource representation expected by the module. Together, the four runs exercise both validation boundaries: `7` and `35` are accepted, while `6` and `36` are rejected.

The `expect_failures` argument applies to custom conditions declared by the module, such as variable validations, preconditions, and postconditions. It does not turn an arbitrary error produced by provider validation into an expected test result. Constraints owned by the module should therefore be expressed at the module boundary instead of relying on a later provider error.

These tests run quickly and expose contract regressions close to their source. If a default, validation rule, or normalization expression changes unexpectedly, the author receives feedback without waiting for Azure resources to be provisioned.

Avoid reproducing every implementation detail in assertions. A test suite that asserts every resource argument makes harmless refactorings expensive and largely duplicates the configuration itself. Focus on accepted and rejected input boundaries, observable policy, resource identity, security-sensitive settings, and behavior promised by the public API.

#### Know what mock providers cannot prove

A mock provider prevents OpenTofu from executing real resource and data source operations through the provider. OpenTofu uses the provider schema to evaluate the configuration, but it does not call Azure or execute the provider's CRUD logic. Computed values are generated according to their types unless the test supplies explicit defaults or overrides.

Consequently, a plan test with a mock provider can verify expression evaluation, resource expansion, input propagation, and assertions over configured arguments. It cannot prove that Azure accepts the request, that the provider normalizes values as expected, that computed attributes contain meaningful data, or that the resource eventually reaches its desired state.

Mock providers reduce the number of scenarios that require real infrastructure. They do not replace deployment tests for behavior owned by Azure or the provider. For more information, see the OpenTofu documentation for [mock providers and automatically generated values](https://opentofu.org/docs/v1.12/cli/commands/test/#the-mock_provider-blocks).

### Treat examples as executable contracts

The examples introduced in [Reusable by design](#reusable-by-design) should do more than demonstrate syntax. Each one should be a representative calling configuration that exercises the module through the same public interface available to its consumers.

When a module exposes meaningful optional capabilities, I normally start with two:

- `examples/default` demonstrates the smallest useful deployment and serves as a fixture for verifying that sensible defaults work together.
- `examples/complete` exercises important optional capabilities and the interactions most likely to reveal integration problems.

Additional examples should represent materially different scenarios rather than every possible input combination. Testing all combinations quickly becomes impractical as the module grows. Select cases that cross meaningful architectural boundaries or exercise interactions most likely to fail.

The [terraform-azurerm-avm-ptn-alz module (v0.21.0)](https://github.com/Azure/terraform-azurerm-avm-ptn-alz/tree/v0.21.0/examples) demonstrates this approach. Alongside its default deployment, it provides focused examples for capabilities and lifecycle scenarios such as AMBA, role assignments, private DNS zones, policy assignment changes, and destroy behavior.

Using examples as deployment fixtures prevents documentation and implementation from drifting apart. A code sample that is never initialized, planned, and applied is only an unverified claim.

### Verify behavior against real Azure

Some properties become observable only after deployment. Azure may reject a combination accepted by the provider schema, populate computed attributes asynchronously, enforce policy, or expose an endpoint only after several control-plane operations have completed.

[Terratest](https://terratest.gruntwork.io/) complements native OpenTofu tests by allowing a Go test to drive the OpenTofu CLI and then inspect the deployed system through HTTP requests, Azure APIs, or other clients.

The AVM E2E and idempotency requirements provide a useful baseline: examples are deployed against Azure, checked for idempotency, and destroyed after the test. Terratest can extend this lifecycle with assertions against behavior visible to a module consumer. For tofu-registry, such a test could follow this structure:

**`test/default_test.go`:**

```go
package test

import (
	"fmt"
	"strings"
	"testing"
	"time"

	http_helper "github.com/gruntwork-io/terratest/modules/http-helper"
	"github.com/gruntwork-io/terratest/modules/logger"
	"github.com/gruntwork-io/terratest/modules/random"
	"github.com/gruntwork-io/terratest/modules/terraform"
)

func TestDefaultExample(t *testing.T) {
	suffix := strings.ToLower(random.UniqueID())
	ctx := t.Context()
	name := fmt.Sprintf("registry-%s", suffix)
	location := "westeurope"

	options := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformBinary: "tofu",
		TerraformDir:    "../examples/default",
		Vars: map[string]interface{}{
			"name":     name,
			"location": location,
		},
	})

	defer terraform.DestroyContext(t, ctx, options)

	logger.Default.Logf(t, "Deploying %s in %s", name, location)
	terraform.InitAndApplyAndIdempotentContext(t, ctx, options)

	endpoint := terraform.OutputContext(t, ctx, options, "endpoint")
	logger.Default.Logf(t, "Validating health endpoint %s", endpoint)

	http_helper.HTTPGetWithRetryContext(
		t,
		ctx,
		endpoint+"/health",
		nil,
		200,
		"ok",
		30,
		10*time.Second,
	)
}
```

This test verifies several different properties:

- [x] The `example` can initialize and deploy with OpenTofu.
- [x] Azure accepts the resulting resource configuration.
- [x] A subsequent plan contains no changes.
- [x] The module exposes an endpoint through its public outputs.
- [x] The deployed application responds as expected.
- [x] Created resources are scheduled for destruction even when an assertion fails.

The final assertion should observe behavior that matters to a consumer. Reading an output and comparing it with the same input passed to the module proves very little. Calling a health endpoint, querying an Azure resource through an independent client, or verifying effective access demonstrates that the deployed system fulfills its contract.

Terratest should not be used for every validation rule or default. Real deployments are slower, cost money, consume subscription quotas, and can fail because of transient platform behavior. Keep the deployment suite small and concentrate it on risks that mocks and plans cannot observe.

### Test idempotency

A successful first deployment proves only that the module can create infrastructure. The same configuration should produce an empty plan when evaluated again. Otherwise, every consumer sees perpetual changes and cannot distinguish configuration drift from unstable module behavior.

Terratest provides [ApplyAndIdempotentContext](https://pkg.go.dev/github.com/gruntwork-io/terratest@v1.0.1/modules/terraform#ApplyAndIdempotentContext) for this purpose. It applies the configuration and verifies that a subsequent plan produces no additional changes. Its [InitAndApplyAndIdempotentContext](https://pkg.go.dev/github.com/gruntwork-io/terratest@v1.0.1/modules/terraform#InitAndApplyAndIdempotentContext) variant also initializes the working directory, which is appropriate for a self-contained example test. The [AVM specification SNFR7: Idempotency Tests](https://azure.github.io/Azure-Verified-Modules/specs/tf/res/#id-snfr7---category-testing---idempotency-tests) similarly treats idempotency as a required property rather than an optional optimization.

### Test upgrade paths as first-class scenarios

Truly reusable modules also need upgrade tests. A fresh deployment exercises only the current configuration against an empty state. It does not test the `moved` blocks, deprecated inputs, changed defaults, or provider behavior that existing consumers encounter during an upgrade.

This extends the fresh-deployment baseline by exercising the transition from an existing module version to the version under development. The [AVM specification SNFR5: Upgrade Tests](https://azure.github.io/Azure-Verified-Modules/specs/tf/res/#id-snfr5---category-testing---upgrade-tests) similarly recommends testing that features introduced in non-major releases remain backward compatible.

An upgrade test should:

1. Deploy an example pinned to an exact, earlier supported module version.
2. Preserve the resulting state, Azure resources, and provider dependency lock file.
3. Update the module call to use the version under test.
4. Run `tofu init` while preserving the provider selections recorded in `.terraform.lock.hcl`, then calculate and save a new plan.
5. Inspect the machine-readable plan and reject unexpected replacements or deletions.
6. Apply the upgrade and verify runtime behavior.
7. Calculate one final plan to confirm idempotency.

The [OpenTofu dependency lock file](https://opentofu.org/docs/v1.12/language/files/dependency-lock/) records provider selections, but not remote module versions. Pin the baseline fixture to an exact published module version, and identify the target revision explicitly rather than relying on a floating constraint. This ensures that the test always exercises the intended upgrade path. Save the plan with `tofu plan -out=upgrade.tfplan` and inspect its machine-readable representation with `tofu show -json upgrade.tfplan` rather than relying on terminal output when classifying replacements, deletions, and expected in-place updates.

At a minimum, test the transition from the latest published release to the version under development. This is especially important for the migration chains described earlier. A `moved` block may work for consumers upgrading from the immediately preceding release while still failing for a workspace that skipped several versions. If the module claims to support direct upgrades across skipped releases, also test the oldest direct path covered by that policy.

An upgrade test should log the source and target module versions and retain the saved plan and its machine-readable representation when it fails. Unless a provider upgrade is deliberately part of the scenario, preserve `.terraform.lock.hcl` and avoid `tofu init -upgrade` so that a failure can be attributed to the module change. The goal is not necessarily an empty upgrade plan. It is a plan whose changes match the migration contract, followed by a successful apply, preserved runtime behavior, and an empty plan after convergence.

Testing every historical version indefinitely is rarely practical. The support policy should define which upgrade paths remain covered, and versioning should communicate when an older path is intentionally removed.

### Make deployment tests reliable and diagnosable

Infrastructure tests operate against distributed APIs and eventually consistent control planes. A resource may have been accepted by Azure while its endpoint, role assignment, or DNS record is not yet observable. Treating every delayed observation as a module failure produces a flaky test suite that engineers eventually stop trusting.

Retries should handle only conditions that are expected to converge or errors known to be transient. [terraform.WithDefaultRetryableErrors](https://pkg.go.dev/github.com/gruntwork-io/terratest@v1.0.1/modules/terraform#WithDefaultRetryableErrors) covers common retryable CLI failures, while helpers such as [HTTPGetWithRetryContext](https://pkg.go.dev/github.com/gruntwork-io/terratest@v1.0.1/modules/http-helper#HTTPGetWithRetryContext) can wait for a deployed endpoint to become ready. Both still need a bounded retry count, delay, and overall deadline. Retrying an entire test or a deterministic validation failure only makes the real defect slower and harder to diagnose.

A successful retry should not erase the attempts that preceded it. A check that fails and later passes is still a reliability signal, not an ordinary success. Preserve the failed observations in the test output and report that the operation recovered after retry. This makes it possible to distinguish expected convergence from a test whose behavior alternates without explanation.

Timeouts should exist at the layer that owns the wait. Where supported, provider resource timeouts bound Azure create, read, update, and delete operations. Context deadlines can bound an individual test phase, while the Go test timeout provides a final limit for the process. The outer timeout must leave enough time for diagnostic collection and cleanup because forcibly terminating the test also prevents deferred cleanup from running.

Failure output should identify the phase, test environment, Azure region, relevant resource names, and the last observed state. Terratest's [logging guidance](https://terratest.gruntwork.io/docs/testing-best-practices/timeouts-and-logging/) recommends its `logger` package for long-running tests because it writes to standard output immediately instead of relying on buffered `t.Log` output. Log identifiers and endpoints, but never credentials, tokens, or sensitive outputs.

Assertions should explain both the expected behavior and the observation that violated it. Preserve the OpenTofu command output and, when practical, collect the status of relevant Azure resources before cleanup. A failure that says only `expected true` forces its reader to reproduce an expensive deployment before investigation can even begin.

Classify failures by the action they require. A module contract regression, an Azure or provider error, quota exhaustion, an authentication failure, and an unsuccessful cleanup should not become the same generic failed test. Classification does not make the build pass. It makes the result actionable and helps the correct owner determine whether to change the module, stabilize the test, repair the environment, or rerun a known transient operation.

Most Terratest helpers also provide an `E` variant that returns an error instead of immediately failing the test. Use these variants when a phase needs to classify a failure, attach additional context, or collect diagnostics before reporting it. The regular helpers remain appropriate when their command output already provides enough context. Terratest documents this distinction in its [error-handling guidance](https://terratest.gruntwork.io/docs/testing-best-practices/error-handling/).

Record enough execution context to compare one run with another: the source revision, OpenTofu version, locked provider versions, example or upgrade path, Azure region, and test stage. When the same test alternates between success and failure with equivalent inputs, that history is strong evidence of nondeterministic behavior. It is much more useful than treating each failed pipeline as an isolated event.

For local execution, disable Go's test cache and set an explicit timeout:

```shell
go test -v -count=1 -timeout 60m ./...
```

The correct timeout depends on the resources being tested. It should be based on observed deployment behavior and the cleanup budget rather than increased whenever a flaky test fails.

Measure the duration of individual stages as well as the complete test. A growing deployment or cleanup time is itself an engineering signal because it lengthens feedback loops and increases the probability of overlapping runs, exhausted quotas, and abandoned environments. Improving the slowest phase is usually more valuable than raising the timeout for the entire suite.

### Keep test stages independently runnable

Even a reliable deployment test becomes painful when every change requires recreating the entire environment. Provisioning, validation, idempotency, diagnostic collection, and destruction are separate phases with different iteration speeds. A developer adjusting an HTTP assertion should be able to rerun validation against the existing environment without waiting for another Azure deployment.

Terratest's [`test_structure` package](https://pkg.go.dev/github.com/gruntwork-io/terratest@v1.0.1/modules/test-structure) can divide a test into named stages and persist the values required by subsequent stages. With helper implementations omitted for clarity, a staged version of the test can follow this structure:

```go
/* Remaining code omitted for clarity */

workingDir := "../examples/default"
ctx := t.Context()

defer testStructure.RunTestStage(t, "destroy", func() {
	options := testStructure.LoadTerraformOptions(t, workingDir)
	terraform.DestroyContext(t, ctx, options)
})

defer testStructure.RunTestStage(t, "diagnostics", func() {
	options := testStructure.LoadTerraformOptions(t, workingDir)
	collectRegistryDiagnostics(t, ctx, options)
})

testStructure.RunTestStage(t, "deploy", func() {
	options := newTerraformOptions(t, workingDir)
	testStructure.SaveTerraformOptions(t, workingDir, options)
	terraform.InitAndApplyContext(t, ctx, options)
})

testStructure.RunTestStage(t, "validate", func() {
	options := testStructure.LoadTerraformOptions(t, workingDir)
	validateRegistry(t, ctx, options)
})

testStructure.RunTestStage(t, "idempotency", func() {
	options := testStructure.LoadTerraformOptions(t, workingDir)
	terraform.ApplyAndIdempotentContext(t, ctx, options)
})
```

Each helper owns one responsibility, and the saved Terraform options allow later stages to reconnect to the same test deployment. Go executes deferred functions in last-in, first-out order, so registering the diagnostics defer after the destroy defer ensures that evidence is collected before resources are removed. Diagnostic collection should be best-effort and must not prevent the destroy stage from running.

The Terratest guide to [iterating locally using test stages](https://terratest.gruntwork.io/docs/testing-best-practices/iterating-locally-using-test-stages/) uses the `SKIP_<stage_name>` environment variable to skip a stage. For example, a developer can rerun only validation against an existing environment:

```shell
SKIP_deploy=true SKIP_idempotency=true SKIP_destroy=true \
  go test -v -count=1 -run TestDefaultExample
```

Skipping `destroy` deliberately leaves billable infrastructure behind. Print the resource group and expiration time prominently, exclude cached stage data from version control, do not persist secrets in it, and retain the independent cleanup mechanism described later. In CI, run the complete lifecycle unless a dedicated recovery workflow explicitly resumes a failed environment.

The same separation supports a deliberate testing strategy. During local development, run the smallest stage that can observe the change. For pull requests, always run the fast contract suite and select deployment fixtures conservatively from the capabilities that changed. Changes to shared expressions, provider requirements, or the module's central resource graph should trigger every deployment fixture they can affect. Before a release, run the complete supported deployment and upgrade suite. Fast feedback is valuable only while the selection rules remain biased toward detecting regressions rather than saving minutes.

### Isolate and clean up deployment tests

Tests that create real infrastructure must run in an Azure subscription separated from production workloads. Terratest makes the same recommendation for infrastructure tests because they perform potentially destructive operations against real environments. Unique names or prefixes should isolate cloud resources created by concurrent runs. Parallel tests must also use separate working directories and isolated backend keys, workspaces, or state files. Unique resource names alone do not protect a shared `.terraform` directory or state. Enable parallel execution only when these boundaries, Azure quotas, and shared dependencies permit it. A shared test harness should establish them consistently by allocating the working directory, state location, resource namespace, and ownership metadata for each run. Terratest documents it as well in its [testing environment](https://terratest.gruntwork.io/docs/testing-best-practices/testing-environment/) guide.

Apply least privilege to test identities as well as production identities. The principal that deploys a fixture should receive only the permissions and scope required by that scenario, preferably within a dedicated test subscription or resource group. A module that creates role assignments or Microsoft Entra resources may require additional privileges, but those permissions should remain narrowly scoped instead of being permanently granted to a general-purpose pipeline identity. The [Azure Well-Architected Framework](https://learn.microsoft.com/en-us/azure/well-architected/security/identity-access) recommends using separate roles instead of elevating existing identities, while the [Azure RBAC best practices](https://learn.microsoft.com/en-us/azure/role-based-access-control/best-practices) recommend granting only the access required at the narrowest practical scope.

When a test verifies authorization, use a separate consumer identity with only the access promised by the module. Reusing the privileged deployment identity can produce a false positive because the request may succeed through permissions that an actual consumer would never possess. An independent cleanup process can similarly use its own identity, authorized to remove expired test resources without gaining access outside the test boundary. Not every module requires three separate principals, but the distinction becomes valuable when testing RBAC, managed identities, Key Vault, Storage, Microsoft Entra, or access across subscriptions.

When using Terratest, always register cleanup before applying the configuration:

```go
defer terraform.DestroyContext(t, ctx, options)
```

The `defer` handles ordinary assertion and apply failures, but it is not a complete cleanup strategy. A terminated runner, expired credential, Azure outage, or process timeout can prevent destruction from finishing. The test subscription should therefore have an independent cleanup mechanism based on resource-group ownership, tags, or an expiration timestamp. Terratest also recommends a separate janitor process for resources left behind when normal cleanup fails. Its [cleanup guidance](https://terratest.gruntwork.io/docs/testing-best-practices/cleanup/) describes both layers.

Here, the module repository needs to define what each test proves, which identity performs it, what infrastructure it may create, and how that infrastructure can be identified and removed. The next article will cover how those identities authenticate from CI, how permissions are divided between jobs, and how ephemeral credentials replace stored secrets.

---

## Distribution

Tests turn compatibility claims into evidence. Versioning gives the tested contract an identity, publishing binds that identity to an immutable release, and a private registry makes the release discoverable to consumers across the organization.

### Version the public contract

[Semantic Versioning](https://semver.org/) assumes that versioned software has a defined public API. For an OpenTofu module, this API includes more than variable and output names. It also covers defaults, validation rules, resource addresses, provider requirements, runtime behavior, and supported upgrade paths.

A patch release should remain backward-compatible with the existing contract. A minor release may add an optional capability without changing the behavior of existing configurations. A major release is required when a previously valid configuration, state, or execution environment is no longer supported.

This makes consumer impact more important than the size of the code change. Renaming an internal local may require only a patch release. Changing a default value can require a major release when it alters plans for consumers who have not changed their configuration.

The [AVM specification SNFR17: Semantic Versioning](https://azure.github.io/Azure-Verified-Modules/specs/tf/res/#id-snfr17---category-release---semantic-versioning) follows the same general model. Before `1.0.0`, AVM uses minor versions for breaking changes and new features. After `1.0.0`, incompatible changes require a new major version.

A registry source address allows consumers to select a specific release:

```hcl
module "tofu_registry" {
  source  = "modules.oczadly.io/infra-at-scale/tofu-registry/azurerm"
  version = "1.4.2"

  /* Remaining code omitted for clarity */
}
```

For production deployments, I prefer exact module versions. OpenTofu's [dependency lock file](https://opentofu.org/docs/v1.12/language/files/dependency-lock/) records provider selections, but it does not currently lock remote module versions. An exact constraint makes an upgrade explicit and allows the new version to pass through the same review and testing process as any other code change.

The automation that calculates releases and proposes dependency upgrades belongs to the next article. Here, the important part is defining what each version means.

### Publish immutable releases

A version becomes useful only when consumers can retrieve the exact code represented by it. Once published, its contents must not change. Reassigning `1.4.2` to another commit invalidates previous test results and prevents consumers from reproducing an earlier deployment.

Each release should identify its semantic version, source commit, and immutable Git reference or module archive. It should also include release notes, migration instructions, and the upgrade paths verified before publication.

Publishing and registry discovery are separate responsibilities. Publishing creates and stores the release, while the registry advertises available versions and tells OpenTofu where a selected version can be downloaded.

A safe publishing sequence is:

1. Build the package from the tested revision.
2. Store it under a version-specific location.
3. Verify that it can be downloaded and initialized.
4. Record its release metadata.
5. Add the version to the registry catalog.

The version should become visible only after its package is available. The [OpenTofu Module Registry Protocol](https://opentofu.org/docs/v1.12/internals/module-registry-protocol/) intentionally defines no publishing endpoint. How a release enters the catalog remains an implementation detail owned by the organization.

The next article will automate this sequence, including release calculation for repository-per-module and monorepo structures.

### Choose a private registry deliberately

Building a private registry should not be the default decision. Several free and open-source options are already available across hosted, self-hosted, and direct module distribution models, although operating them may still incur infrastructure costs.

| Option | Delivery model | Best fit |
|---|---|---|
| [Public OpenTofu Registry](https://opentofu.org/registry/) | Public hosted registry | Modules intended for the wider OpenTofu community |
| Direct Git, HTTP, or object-storage sources | Direct package retrieval | Small organizations that can accept source references instead of native registry version selection |
| [OpenTofu modules in an OCI registry](https://opentofu.org/docs/cli/oci_registries/) | OCI artifact distribution | Organizations already operating ACR, GHCR, Harbor, or another OCI Distribution 1.1 implementation |
| [GitLab Terraform Module Registry](https://docs.gitlab.com/user/packages/terraform_module_registry/) | GitLab-hosted package registry | Teams already using GitLab for source control and CI/CD |
| [Terrakube Private Registry](https://docs.terrakube.io/user-guide/private-registry) | Self-hosted registry and collaboration platform | Organizations that want an internally operated Terraform or OpenTofu registry and collaboration platform |

Direct source and OCI options can distribute modules without implementing the native [OpenTofu Module Registry Protocol](https://opentofu.org/docs/v1.12/internals/module-registry-protocol/). They are valid alternatives, but their source addresses, authentication, version selection, and discovery experience differ from a registry source using `hostname/namespace/name/system`.

Pricing, licensing, and product tiers change more frequently than registry protocols. Evaluate the current terms and OpenTofu compatibility of a selected platform before adopting it.

If one of these options already satisfies your requirements, operating another registry will only add maintenance, security, and availability responsibilities. A custom implementation is justified only when a deliberately smaller architecture or organization-specific integration creates enough value to outweigh owning its authentication, authorization, catalog, protocol compatibility, upgrades, and availability.

### Adopt Terrakube as the reference implementation

When I outlined this series, I planned to build a lightweight `tofu-registry` service using Azure Functions and Azure Storage. The exercise would have been a useful way to understand service discovery, version resolution, authentication, and package delivery beneath `tofu init`.

Research changed that decision. [Terrakube](https://terrakube.io/) already provides a self-hosted private registry for modules and providers, supports OpenTofu and Terraform workflows, and integrates with identity providers such as GitHub and Microsoft Entra ID through [Dex](https://dexidp.io/). Building another registry would reproduce capabilities that an active open-source project already maintains without creating enough additional value to justify the implementation and maintenance effort.

The reference implementation will therefore adopt Terrakube rather than build a custom registry. This is not a universal recommendation. Terrakube is a broader collaboration platform with a larger operational footprint than an object store or OCI registry. An organization that needs only package distribution and already operates Azure Container Registry (ACR) may prefer the simpler OCI path. Terrakube fits this series because the reference platform needs an authenticated internal catalog, while the next article will extend it with organization-wide automation.

This changes the implementation, not the architectural responsibilities. The platform still needs an explicit deployment topology, TLS and DNS, durable storage and backups, identity integration, least-privilege permissions, an immutable publishing path, observability, and a tested upgrade strategy. Adopting a product removes undifferentiated implementation work, but it does not remove the need to operate the resulting service deliberately.

This section focuses on Terrakube's role in the module distribution lifecycle, the tradeoffs behind adopting it, and how OpenTofu discovers and consumes published packages. The next article will cover its integration with Azure, Microsoft Entra ID, and secure publishing workflows.

The following practical considerations incorporate feedback from Terrakube maintainers, and describe the boundaries that should be validated before adopting the platform.

### Practical considerations when adopting Terrakube

Terrakube's container-based deployment model makes the platform portable across environments. It can run locally with Docker Compose, on a managed container platform such as Azure Container Apps, or on Kubernetes through Azure Kubernetes Service (AKS).

Azure Container Apps is not currently documented as an official Terrakube deployment target. It can nevertheless be a useful option for small teams that want to evaluate whether Terrakube fits their needs without operating an AKS cluster or its node pools. This removes the need to operate Kubernetes platform components such as ingress or gateway controllers, cert-manager, and ExternalDNS, including their lifecycle management, upgrades, and troubleshooting.

For a production deployment, AKS is the more established option because Terrakube's documented deployment model is based on Helm and Kubernetes. It offers the control needed to define availability, networking, persistent storage, upgrades, and operational boundaries deliberately. Azure Container Apps remains a promising alternative when reducing platform-management overhead is more important than Kubernetes-level control, but it should be validated against the required availability, backup, upgrade, and observability scenarios before being adopted as a production baseline.

Capacity planning applies to the registry as well as to the underlying platform. As usage grows, run the registry with an appropriate number of replicas and verify its behavior under the expected package-download and publishing load. Published module packages should also contain only the files required by their consumers. Accidental inclusion of large, unrelated artifacts can create unnecessary storage, transfer, and reliability problems for the registry.

Registry access should also follow least-privilege principles. Use a team token with only the permissions required by the publishing or consumption workflow instead of a personal access token with broader access. This keeps automation independent of an individual user and makes the credential's ownership and rotation responsibility explicit.

Terrakube can organize modules and workspaces across multiple organizations rather than treating the platform as a single global boundary. When organizations reflect teams, domains, or ownership boundaries, registry permissions and the module catalog are easier to keep understandable as the platform grows.

Provider distribution deserves a separate validation step. In Terrakube, a private provider implementation is currently configured through the API. Do not assume that publishing and consuming providers follow precisely the same workflow as module publication; verify it as part of the selected distribution path.

Technical standardization only works when consumers have a clear path to request missing capabilities or contribute improvements to the modules they depend on.

These operational choices do not change the contract seen by a module consumer. Any registry that implements the [OpenTofu Module Registry Protocol](https://opentofu.org/docs/v1.12/internals/module-registry-protocol/) exposes the same discovery and package-resolution flow to OpenTofu. The registry hostname participates in service discovery, advertises available versions, and resolves the selected version to an immutable package. Terrakube adds a catalog, permissions, provider distribution, and broader collaboration workflows around that exchange, but `tofu init` still begins with the same protocol.

The following reference implementation applies these boundaries to a concrete Terrakube deployment on Azure, while keeping the consumer-facing module workflow deliberately conventional.

### A small reference implementation

## Summary

This article followed an OpenTofu module through its complete lifecycle: designing a focused API, preserving resource identity, making dependencies explicit, testing behavior and upgrade paths, publishing immutable releases, and making them discoverable through a registry. These practices reinforce one another, but adopting all of them is not a goal in itself.

On a diagram, this lifecycle looks clean. Reality includes delivery deadlines, legacy state, limited access to dedicated test subscriptions, cloud costs, and teams at different levels of maturity. Engineering quality therefore needs to be translated into outcomes that the business can evaluate. Effective project leaders make these tradeoffs visible through hard data:

> What the company will gain, what it stands to lose, and what risks it will face if a change is made or left undone.

That evidence can include the time spent maintaining duplicated implementations, the lead time required to provision an environment, incidents caused by unsafe upgrades, the effort needed to roll out a security fix, or the cost of abandoned test infrastructure. The data may justify a complete internal module platform. It may also show that a smaller contract suite and direct module sources are sufficient for the current scale. Both are valid engineering outcomes.

The goal is not to implement every practice on day one. It is to make each new layer of abstraction earn its cost through safer changes, shorter lead times, or lower operational risk. At organizational scale, truly reusable modules are not merely shared code. They are maintained infrastructure capabilities that engineering teams can evolve safely and the business can rely on.

{{< buymeacoffee >}}

<!--

Dodać jeszcze, jeśli jest za mało opisane:
* SemVer wraz z klasyfikacją breaking changes;
* publikowanie: tagi, immutable releases, uwierzytelnienie, discovery i protokół registry;
-->
