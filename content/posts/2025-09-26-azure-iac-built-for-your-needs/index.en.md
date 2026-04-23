---
title: "Azure IaC built for your needs"
subtitle: "Architectural patterns. A foundation to scale powered by OpenTofu and AVM."
series: ["Infrastructure at scale with Azure and OpenTofu"]
date: 2025-09-26
description: "Architectural patterns. A foundation to scale powered by OpenTofu and AVM."
draft: false
resources:
- name: "featured-image"
  src: "featured-image.png"
---

Over the years, I've had the opportunity to work on many projects and see a wide range of approaches to Infrastructure as Code using [Terraform](https://developer.hashicorp.com/terraform).
Some of them scaled well, others didn't. A few worked great early on, but as the project grew, and new resources had to be added under time pressure and shifting priorities, the codebase became harder and harder to maintain.
It was still "infrastructure as code", but each change took longer, and refactoring became too costly to be worth the effort.

These experiences helped me define **how I want to structure Infrastructure as Code** in new projects and how I'd approach migrating existing cloud resources into version-controlled repositories.

This series is also a great chance to organize and consolidate my [Microsoft Azure](https://azure.microsoft.com/) knowledge in a practical way: one that brings real value to both you and me.

So let me invite you to the series **"Infrastructure at Scale with Azure and OpenTofu"**.
Below is a list of articles and what you'll find in each one.

{{< admonition abstract "About this series" >}}
This article is part of the **"Infrastructure at Scale with Azure and OpenTofu"** series. The full series includes:

- [ ] [**Azure IaC built for your needs**](#) (you're reading this one now)

  Explore multiple patterns for organizing Infrastructure as Code — their strengths, tradeoffs, and when to use which.
  I'll walk you through a proven skeleton that you can adapt in your org or team.

- [ ] Build flexible infrastructure modules and a custom registry

  Learn how to design [OpenTofu](https://opentofu.org/) modules that are idiomatic, reusable, versioned, and ready to share.
  I'll also show you how to build a lightweight module registry you can host anywhere.

- [ ] Design CI/CD for your Infrastructure as Code workflows

  See how a solid CI/CD pipeline can streamline your infrastructure development.
  We'll cover tools, automation, and proven patterns to help your code ship faster and safer.

{{< /admonition >}}


## Assumptions

Before we dive in, let's quickly go over a few assumptions.
In this series, I'll be using:

* [Microsoft Azure](https://azure.microsoft.com/) because I want to solidify my knowledge of Azure while building something genuinely useful.
* [OpenTofu](https://opentofu.org/) because it's a fully open-source alternative to [Terraform](https://developer.hashicorp.com/terraform).
* [GitHub](https://github.com/) because it's still the most common platform for hosting code and automating CI/CD pipelines.

While the series is focused on [Microsoft Azure](https://azure.microsoft.com/), [OpenTofu](https://opentofu.org/) and [GitHub](https://github.com/), most of the infrastructure patterns you'll see here can be adapted to other clouds, or used with [Terraform](https://developer.hashicorp.com/terraform), [GitLab](https://gitlab.com/) or any CI/CD tool of your choice.

## How you can design IaC on Azure

Let's start with a broad overview of how Infrastructure as Code can be structured on [Microsoft Azure](https://azure.microsoft.com/) using [OpenTofu](https://opentofu.org/). I'll walk you through several real-world models — each with its strengths and tradeoffs.

After that, I'll show you the structure I use in my own projects.

{{< admonition note "Heads up" >}}
You won't see `for_each` or `count` in these examples. That's on purpose.
The goal here is to focus on repository structure, module versioning, and state boundaries, not on implementation details.
We'll revisit the technical patterns later in this series.
{{< /admonition >}}

### Monorepo

<!-- 1. Description -->
In this model, all infrastructure code lives in a single repository.
It's typically structured by environments (for example, `dev` (1️⃣) and `prod` (2️⃣)) and within each environment, directories like `databases` (3️⃣) or `network` (4️⃣) group related resources (`resource`) and/or modules (`module`).
Each state file covers many components, which becomes harder to manage over time.

<!-- 2. Example structure -->
A typical monorepo structure might look like this:

```text
tofu-infrastructure
├── dev 1️⃣
│   ├── databases 3️⃣
│   │   ├── main.tf
│   │   └── providers.tf
│   └── network 4️⃣
│       ├── main.tf
│       └── providers.tf
└── prod 2️⃣
    ├── databases 3️⃣
    │   ├── main.tf
    │   └── providers.tf
    └── network 4️⃣
        ├── main.tf
        └── providers.tf
```

Example environment files:

* `prod/databases/main.tf`

```hcl
resource "azurerm_postgresql_flexible_server" "checkout_db" {
  /* Remaining code omitted for clarity */
}

resource "azurerm_postgresql_flexible_server" "shipping_db" {
  /* Remaining code omitted for clarity */
}
```

* `dev/databases/main.tf`

```hcl
resource "azurerm_postgresql_flexible_server" "checkout_db" {
  /* Remaining code omitted for clarity */
}

resource "azurerm_postgresql_flexible_server" "shipping_db" {
  /* Remaining code omitted for clarity */
}
```

<!-- 3. Adding resources -->
Adding a new resource requires duplicating it across every relevant environment.

<!-- 4. Environment onboarding -->
Creating a new environment means adding another folder in the monorepo and defining all required resources there.

<!-- 5. Logic changes -->
Adding functionality or refactoring often requires updates across multiple folders — both within a single environment and between them. This wide blast radius increases friction and makes such initiatives less likely to happen.

<!-- 6. Maintenance -->
Upgrading module or provider versions often means editing many directories at once. This discourages regular updates and increases the risk of technical debt.

<!-- 7. Pros & cons -->
#### Pros & cons

✅ **Quick to get started**. Great for proof of concept or short-term experimentation.

❌ **Doesn't scale well**. As your infra grows, so does the maintenance burden.

❌ **Large state files**. Shared state across many components slows down changes and complicates deployments.

<!-- 8. When to choose it? -->
{{< admonition question "When is this a good fit?" >}}
In my opinion: _only for small side projects or internal experiments. I wouldn't recommend it for any serious production-grade infrastructure._
{{< /admonition >}}

---

### Monorepo + local modules

<!-- 1. Description -->
In this approach, resources are defined as local modules.
The repository contains a `modules` directory (1️⃣) with versioned infrastructure modules.
Each environment (e.g., `dev` (2️⃣), `prod` (3️⃣)) has its own directory with state files that call those modules.

State files still manage multiple resources, which limits independence and becomes harder to maintain over time.

<!-- 2. Example structure -->
Here's what the structure might look like in practice:

```text
tofu-infrastructure
├── environments
│   ├── dev 2️⃣
│   │   ├── databases
│   │   │   ├── main.tf
│   │   │   └── providers.tf
│   │   └── network
│   │       ├── main.tf
│   │       └── providers.tf
│   └── prod 3️⃣
│       ├── databases
│       │   ├── main.tf
│       │   └── providers.tf
│       └── network
│           ├── main.tf
│           └── providers.tf
└── modules 1️⃣
    ├── database-1.0
    ├── database-1.1
    ├── database-1.2
    └── vnet-1.0
```

Typical module calls:

* `environments/prod/databases/main.tf`

```hcl
module "checkout_db" {
  source = "../../../modules/database-1.0"
  /* Remaining code omitted for clarity */
}

module "shipping_db" {
  source = "../../../modules/database-1.0"
  /* Remaining code omitted for clarity */
}
```

* `environments/dev/databases/main.tf`

```hcl
module "checkout_db" {
  source = "../../../modules/database-1.1"
  /* Remaining code omitted for clarity */
}

module "shipping_db" {
  source = "../../../modules/database-1.2"
  /* Remaining code omitted for clarity */
}
```

<!-- 3. Adding resources -->
Adding new resources typically means reusing an existing module.
This reduces duplication — the only repetition is in module declarations.

<!-- 4. Environment onboarding -->
Creating a new environment involves adding a directory and referencing the required local modules.

<!-- 5. Logic changes -->
When a module needs to be changed or refactored, a new directory is created (e.g., `database-1.1`), and modifications are made there. However, as the number of module versions and apps grows, maintaining compatibility and testing across environments becomes more challenging.

<!-- 6. Maintenance -->
Upgrading module or provider versions still requires multiple edits across the codebase, but modularization makes this more manageable. If you want to keep a consistent version across environments, each reference must be updated manually.

<!-- 7. Pros & cons -->
#### Pros & cons

✅ **Improved code reuse**. Local modules help standardize and avoid repetition.

✅ **More structure than raw monorepo**. The modules folder encourages organization.

❌ **False sense of structure**. Without strong conventions, complexity can creep in quickly.

❌ **High cost of updates**. Multiple versions mean more testing and more places to update.

❌ **State is still too large**. Shared state files limit parallel development and slow things down.

<!-- 8. When to choose it? -->
{{< admonition question "When is this a good fit?" >}}
In my opinion: _this may work well for small teams and limited infrastructure — even in production. But as your infra grows, maintaining many local module versions becomes a serious burden._
{{< /admonition >}}

---

### Repo per service + repo per module

<!-- 1. Description -->
This approach is the opposite of a monorepo. It resembles microservice architecture: each part is isolated and managed independently. Every repository corresponds to a specific service or infrastructure layer (for example, `tofu-networking` for networking, `tofu-databases` for the data layer (1️⃣)). Each of them contains environment-specific folders — like `dev` (2️⃣) and `prod` (3️⃣).

These service repos contain module invocations, while the actual logic for resource creation lives in separate module repositories (for example, [terraform-azurerm-avm-res-resources-resourcegroup](https://github.com/Azure/terraform-azurerm-avm-res-resources-resourcegroup) from the [Azure Verified Modules](https://azure.github.io/Azure-Verified-Modules/), or your organization's private registry). Modules can be used from a registry (by version) or directly from the repo (by commit or tag), following [OpenTofu documentation](https://opentofu.org/docs/language/modules/sources/).

Alternatively, modules can be stored locally — in a `modules` folder within the service repository. However, be mindful of the limitations described earlier.

Although the repositories are smaller, the state files still often cover many resources — which may become hard to maintain over time.

<!-- 2. Example structure -->
Example structure for the database layer repo:

```text
tofu-databases 1️⃣
├── dev 2️⃣
│   ├── main.tf
│   └── providers.tf
└── prod 3️⃣
    ├── main.tf
    └── providers.tf
```

Typical environment files:

* `prod/main.tf`:

```hcl
module "checkout_db" {
  source  = "modules.example.net/database/azurerm"
  version = "1.0.0"

  /* Remaining code omitted for clarity */
}

module "shipping_db" {
  source  = "modules.example.net/database/azurerm"
  version = "1.0.0"

  /* Remaining code omitted for clarity */
}

/* Remaining code omitted for clarity */
```

* `dev/main.tf`:

```hcl
module "checkout_db" {
  source  = "modules.example.net/database/azurerm"
  version = "1.1.0"

  /* Remaining code omitted for clarity */
}

module "shipping_db" {
  source  = "modules.example.net/database/azurerm"
  version = "1.2.0"

  /* Remaining code omitted for clarity */
}

/* Remaining code omitted for clarity */
```

<!-- 3. Adding resources -->
Adding new resources using modules is fast. Smaller repos reduce conflicts and developer friction — a common pain point in large monorepos.

<!-- 4. Environment onboarding -->
That said, having many repositories — each tied to a specific service — can make onboarding new environments cumbersome. You'll often need to create pull requests in every repo to add the new environment folder.

<!-- 5. Logic changes -->
Module changes do not directly impact the service repo, which simplifies testing and development. However, be careful with dependencies — if module A exposes outputs used by module B, any change to those outputs requires refreshing the state in dependent modules.

It's worth setting up CI/CD for modules to accelerate their development and ensure quality.

<!-- 6. Maintenance -->
Maintaining this setup requires discipline. Module and provider versions must be updated in many repositories. Automation tools (like Renovate) and strong team practices help keep things manageable.

#### Pros & cons

✅ **Low entry barrier**. Thanks to their small size, service repos are easy to understand — especially for new team members.

✅ **Safe refactoring**. Logic updates don't directly affect live infrastructure. You can test them independently.

❌ **Environment onboarding is complex**. Adding a new environment means touching many repos (and creating many PRs).

❌ **State file growth**. State files may still hold many resources, which hinders parallel work and slows down `plan` and `apply`.

<!-- 8. When to choose? -->
{{< admonition question "When should you choose this approach?" >}}
In my opinion: _best suited for larger teams and more complex infrastructures — especially when environments don't change frequently. Make sure to set up CI/CD for your modules and automate version updates._
{{< /admonition >}}

---

### Monorepo + repo per module

<!-- 1. Description -->
This approach combines centralized root modules with versioned infrastructure logic stored in separate module repositories. The root modules (which hold the state files) live in a single repository. Typically, the structure is segmented by environment (`dev` (1️⃣), `prod` (2️⃣), etc.). Inside each environment folder are directories for specific infrastructure areas such as `databases` (3️⃣) and `network` (4️⃣).

Infrastructure modules are located in separate repositories (just like in the previous approach) and can be referenced from a remote registry (using a version) or directly from a repository (using a commit or tag).

By centralizing state files, it's easier to coordinate deployments across teams. However, these state files often still manage many resources, which can make independent development and testing more difficult.

<!-- 2. Example structure -->
The structure is similar to earlier examples. It might look like this:

```text
tofu-infrastructure
├── dev 1️⃣
│   ├── databases 3️⃣
│   │   ├── main.tf
│   │   └── providers.tf
│   └── network 4️⃣
│       ├── main.tf
│       └── providers.tf
└── prod 2️⃣
    ├── databases 3️⃣
    │   ├── main.tf
    │   └── providers.tf
    └── network 4️⃣
        ├── main.tf
        └── providers.tf
```

Typical module usage within environments:

* `prod/databases/main.tf`:

```hcl
module "checkout_db" {
  source  = "modules.example.net/database/azurerm"
  version = "1.0.0"

  /* Remaining code omitted for clarity */
}

module "shipping_db" {
  source  = "modules.example.net/database/azurerm"
  version = "1.0.0"

  /* Remaining code omitted for clarity */
}

/* Remaining code omitted for clarity */
```

* `dev/databases/main.tf`:

```hcl
module "checkout_db" {
  source  = "modules.example.net/database/azurerm"
  version = "1.1.0"

  /* Remaining code omitted for clarity */
}

module "shipping_db" {
  source  = "modules.example.net/database/azurerm"
  version = "1.2.0"

  /* Remaining code omitted for clarity */
}

/* Remaining code omitted for clarity */
```

<!-- 3. Adding resources -->
Adding new resources works similarly to monorepo setups with local modules — it typically means invoking an existing module again. The modular structure avoids code duplication.

<!-- 4. Environment onboarding -->
Onboarding a new environment involves creating a new folder and initializing the backend for state. Since everything is centralized in one repository, onboarding is relatively fast — assuming the folder structure is well-organized.

<!-- 5. Logic changes -->
Changing module logic means creating a new version (e.g., 1.1.0) and rolling it out in the appropriate environment folder. This makes it easy to introduce new features or refactor existing logic. CI/CD pipelines for modules are recommended to streamline delivery.

<!-- 6. Maintenance -->
Maintenance is moderately complex. Versioning modules makes changes more predictable. However, centralizing the state means that changes to shared components (e.g., provider updates) can have a wide impact and require more thorough testing.

<!-- 7. Pros and cons -->
#### Pros & cons

✅ **Single source of truth**. The entire infrastructure is visible and managed in one place.

✅ **Faster environment onboarding**. Adding a new environment (e.g., trial or test) only requires creating a folder in the monorepo and referencing the required modules.

✅ **Easier development and maintenance**. Refactoring and expanding logic is safer and more ergonomic.

❌ **Large state files**. Centralized state can lead to conflicts during changes, slower plan operations, and challenges with parallel development.

<!-- 8. When to choose? -->
{{< admonition question "When should you choose this approach?" >}}
In my opinion: _this works well for medium and large teams that prefer a centralized repository while leveraging the flexibility and versioning of external modules. It does require a disciplined folder structure, CI/CD for modules, and automated version updates._
{{< /admonition >}}

---

### Comparison

To wrap up this section, I've compiled all the approaches into a single table to help you choose a strategy that best fits your team's structure, infrastructure scale, and operating model.

| Approach                                                                 | Adding resources  | Environment onboarding | Refactoring | Maintenance | State size |
| ------------------------------------------------------------------------ | :---------------: | :--------------------: | :---------: | :---------: | :--------: |
| [Monorepo](#monorepo)                                                    | fast              | fast                   | hard        | hard        | large      |
| [Monorepo + local modules](#monorepo--local-modules)                     | fast              | fast                   | medium      | medium      | large      |
| [Repo per service + repo per module](#repo-per-service--repo-per-module) | fast              | slow                   | easy        | medium      | medium     |
| [Monorepo + repo per module](#monorepo--repo-per-module)                 | fast              | fast                   | easy        | medium      | large      |

The radar chart below visualizes the key traits of each model to help you choose the approach that best fits your context.

{{< echarts >}}
{
  "title": {
    "text": "IaC Architecture Patterns: A Comparison",
    "top": "1%",
    "left": "center"
  },
  "legend": {
    "top": "90%",
    "data": [
      "Monorepo",
      "Monorepo + local modules",
      "Repo per service + repo per module",
      "Monorepo + repo per module"
    ]
  },
  "radar": {
    "indicator": [
      { "name": "Adding resources", "max": 3 },
      { "name": "Environment onboarding", "max": 3 },
      { "name": "Refactoring", "max": 3 },
      { "name": "Maintenance", "max": 3 },
      { "name": "State size", "max": 3 }
    ]
  },
  "series": [
    {
      "type": "radar",
      "data": [
        {
          "value": [3, 3, 1, 1, 1],
          "name": "Monorepo"
        },
        {
          "value": [3, 3, 2, 2, 1],
          "name": "Monorepo + local modules"
        },
        {
          "value": [3, 1, 3, 2, 2],
          "name": "Repo per service + repo per module"
        },
        {
          "value": [3, 3, 3, 2, 1],
          "name": "Monorepo + repo per module"
        }
      ]
    }
  ]
}
{{< /echarts >}}

---

## How I Design IaC in Azure

After reviewing various strategies for organizing infrastructure as code, it's time to show you the structure I personally use: scalable, modular, and aligned with [Azure Verified Modules](https://azure.github.io/Azure-Verified-Modules/). It builds on the [Monorepo + repo per module](#monorepo--repo-per-module) approach, but includes several important nuances.

This approach consists of two main parts:

* Core
* Application infrastructure

Each is described in detail in the following sections.

### Core: `organization-template`

The monorepo portion is called [organization-template](https://github.com/infra-at-scale/organization-template), and I treat it as a solid starting point for any organization, regardless of size or complexity. It provides ready-to-use [OpenTofu](https://opentofu.org/) code based on [Azure Verified Modules](https://azure.github.io/Azure-Verified-Modules/), helping you set up foundational infrastructure for your [Microsoft Azure](https://azure.microsoft.com/) environment.

#### Contents

The [organization-template](https://github.com/infra-at-scale/organization-template) includes, among others:

* Definitions of IAM roles and applications in [Microsoft Entra ID](https://www.microsoft.com/security/business/microsoft-entra).
* Definitions of [Resource Groups](https://learn.microsoft.com/en-us/azure/azure-resource-manager/management/manage-resource-groups-portal#what-is-a-resource-group) required in your [Subscriptions](https://learn.microsoft.com/en-us/microsoft-365/enterprise/subscriptions-licenses-accounts-and-tenants-for-microsoft-cloud-offerings?view=o365-worldwide#subscriptions).
* Networking layer definitions for your applications.

The structure is clean, easy to maintain, and ready to extend.

#### Naming convention

The root directory contains folders for each infrastructure area. They follow the convention:

{{< raw >}}
<center>
<span style="font-size: 2em; font-weight:600;">
<span style="color:#bcb908;">${nn}</span>-<span style="color:#765306;">${optional-area}</span>-<span style="color:#718051;">${azure-service}</span>
</span>
</center>
{{< /raw >}}

For example:

* [02-iam-applications](https://github.com/infra-at-scale/organization-template/tree/v1.0.0/02-iam-applications)
* [03-resourcegroups](https://github.com/infra-at-scale/organization-template/tree/v1.0.0/03-resourcegroups)

If multiple directories share the same prefix number (such as [04-backupvaults](https://github.com/infra-at-scale/organization-template/tree/v1.0.0/04-backupvaults) and [04-networking-nsgs](https://github.com/infra-at-scale/organization-template/tree/v1.0.0/04-networking-nsgs)), they can be applied in parallel since they are not interdependent.

This naming convention makes the execution order immediately clear. It also enables partial parallelization during deployment, which reduces execution time.

When new areas are added, a new numbered directory is created. If necessary, existing numbers may be adjusted. Independent areas can share the same prefix number.

#### Hierarchy

Each infrastructure domain follows a consistent directory structure:

{{< raw >}}
<center>
<span style="font-size: 1.5em; font-weight:600;">
<span style="color:#bcb908;">${area}</span>/<span style="color:#765306;">${optional-subscription-name}</span>/<span style="color:#718051;">${optional-resources-group-name}</span>/<span style="color:#e4d297ff;">${root-module}</span>
</span>
</center>
{{< /raw >}}

Examples:

* [02-iam-applications/github-actions](https://github.com/infra-at-scale/organization-template/tree/v1.0.0/02-iam-applications/github-actions): applications in [Microsoft Entra ID](https://www.microsoft.com/security/business/microsoft-entra) are not bound to any [Subscription](https://learn.microsoft.com/en-us/microsoft-365/enterprise/subscriptions-licenses-accounts-and-tenants-for-microsoft-cloud-offerings?view=o365-worldwide#subscriptions) or [Resource Group](https://learn.microsoft.com/en-us/azure/azure-resource-manager/management/manage-resource-groups-portal#what-is-a-resource-group), so both are omitted.
* [03-resourcegroups/your-subscription/rg-default-eastus](https://github.com/infra-at-scale/organization-template/tree/v1.0.0/03-resourcegroups/your-subscription/rg-default-eastus): the [resource group](https://learn.microsoft.com/en-us/azure/azure-resource-manager/management/manage-resource-groups-portal#what-is-a-resource-group) `rg-default-eastus` belongs to a specific [Subscription](https://learn.microsoft.com/en-us/microsoft-365/enterprise/subscriptions-licenses-accounts-and-tenants-for-microsoft-cloud-offerings?view=o365-worldwide#subscriptions), so only the `${optional-subscription-name}` segment is used.
* [05-networking-vnets/your-subscription/rg-default-eastus/vnet-default-eastus](https://github.com/infra-at-scale/organization-template/tree/v1.0.0/05-networking-vnets/your-subscription/rg-default-eastus/vnet-default-eastus): the virtual network is scoped under both a [Resource Group](https://learn.microsoft.com/en-us/azure/azure-resource-manager/management/manage-resource-groups-portal#what-is-a-resource-group) and a [Subscription](https://learn.microsoft.com/en-us/microsoft-365/enterprise/subscriptions-licenses-accounts-and-tenants-for-microsoft-cloud-offerings?view=o365-worldwide#subscriptions), so both segments are defined.

This hierarchy mirrors Azure's native resource path convention, for example:

```text
/subscriptions/${subscription-id}/resourceGroups/rg-default-eastus/providers/Microsoft.Network/virtualNetworks/vnet-default-eastus
```

This makes it easier to navigate the codebase.

In the approach I recommend, each [VNet](https://learn.microsoft.com/en-us/azure/virtual-network/virtual-networks-overview) has its own isolated state file.

This makes changes faster to apply and easier to understand. Smaller state scopes also reduce the risk of conflicts and improve parallel execution.

Additionally, the paths to state files in the [Storage Account](https://learn.microsoft.com/en-us/azure/storage/common/storage-account-overview) match the project structure. For example, for the directory [03-resourcegroups/your-subscription/rg-default-eastus](https://github.com/infra-at-scale/organization-template/tree/v1.0.0/03-resourcegroups/your-subscription/rg-default-eastus), the backend config looks like this:

```hcl
terraform {
  backend "azurerm" {
    key = "03-resourcegroups/your-subscription/rg-default-eastus/terraform.tfstate"
    /* Remaining config omitted for brevity */
  }
}
```

#### Root module contents

A root module is a directory that initializes the backend state (`terraform` block) and manages a specific set of resources. It typically includes the following files:

* `data.tf` – used for data lookups and accessing remote state outputs from other root modules.
* `locals.tf` – contains reusable values and computed expressions.
* `main.tf` – calls infrastructure modules and/or defines resources.
* `outputs.tf` – exposes values needed in other root modules.
* `providers.tf` – defines providers and remote state configurations.

Resource naming is handled using the [naming](https://registry.terraform.io/modules/Azure/naming/azurerm/latest) module, which ensures compliance with [Microsoft Azure](https://azure.microsoft.com/) naming conventions. For resources not yet supported by that module, names are created using [Azure's recommended abbreviations](https://learn.microsoft.com/en-us/azure/cloud-adoption-framework/ready/azure-best-practices/resource-abbreviations).

Root modules also use [Azure Verified Modules (AVM)](https://azure.github.io/Azure-Verified-Modules/). For example, the root module at [05-networking-vnets/your-subscription/rg-default-eastus/vnet-default-eastus](https://github.com/infra-at-scale/organization-template/tree/v1.0.0/05-networking-vnets/your-subscription/rg-default-eastus/vnet-default-eastus) uses the [avm-res-network-virtualnetwork](https://registry.terraform.io/modules/Azure/avm-res-network-virtualnetwork/azurerm/latest) module. Its code looks like this:

```hcl
module "naming" {
  source  = "Azure/naming/azurerm"
  version = "0.4.2"

  suffix = ["apps"]
}

module "vnet" {
  source  = "Azure/avm-res-network-virtualnetwork/azurerm"
  version = "0.10.0"

  address_space = ["10.0.0.0/16"]
  # Resource group location can be used from other module via remote state:
  location = data.terraform_remote_state.rg_default_eastus.outputs.resource.location
  # VNet name set with the help of the naming module:
  name = module.naming.virtual_network.name
  # Resource group name can be used from other module via remote state:
  resource_group_name = data.terraform_remote_state.rg_default_eastus.outputs.resource.name
  subnets = {
    "${module.naming.subnet.name}-1" = {
      name             = "${module.naming.subnet.name}-1"
      address_prefixes = ["10.0.0.0/24"]

      # NSG can be used from other module via remote state:
      network_security_group = data.terraform_remote_state.nsg_default_apps.outputs.resource
    }
    "${module.naming.subnet.name}-2" = {
      name             = "${module.naming.subnet.name}-2"
      address_prefixes = ["10.0.1.0/24"]

      # NSG can be used from other module via remote state:
      network_security_group = data.terraform_remote_state.nsg_default_apps.outputs.resource
    }
  }
  /* Remaining code omitted for clarity */
}
```

I intentionally avoid creating wrapper modules when the resources are simple or when an official [AVM](https://azure.github.io/Azure-Verified-Modules/) module is likely to be released.

My goal is to deliver an experience that is idiomatic, native to [Microsoft Azure](https://azure.microsoft.com/), and easy to migrate to official [AVM](https://azure.github.io/Azure-Verified-Modules/) modules when they become available.

#### Dependencies between root modules

As you've likely noticed, instead of hardcoding values directly into root modules, I pass them via outputs and remote state from other root modules. For example:

```hcl
# Resource group name can be used from other module via remote state:
resource_group_name = data.terraform_remote_state.rg_default_eastus.outputs.resource.name
```

The remote state is declared like this:

```hcl
data "terraform_remote_state" "rg_default_eastus" {
  backend = "azurerm"
  config = {
    key = "03-resourcegroups/your-subscription/rg-default-eastus/terraform.tfstate"
    /* Remaining config omitted for clarity */
  }
}
```

This works in conjunction with outputs declared in the other module, like this one from [03-resourcegroups/your-subscription/rg-default-eastus](https://github.com/infra-at-scale/organization-template/tree/v1.0.0/03-resourcegroups/your-subscription/rg-default-eastus):

```hcl
output "resource" {
  value = module.rg.resource
}
```

#### Execution Order

Now that you've seen how [organization-template](https://github.com/infra-at-scale/organization-template) is structured (naming conventions, folder hierarchy, root module layout, and interdependencies), let's discuss how to actually apply these modules.

Each root module should be applied according to the numeric prefix in its directory name. These numbers reflect dependencies and allow for parallel execution of modules that do not depend on one another.

The state dependency diagram below shows the execution flow between modules:

{{< mermaid >}}
stateDiagram-v2
    01_iam_custom_roles: 01-iam-custom-roles
    02_iam_applications: 02-iam-applications
    03_resource_groups: 03-resourcegroups
    04_backup_vaults: 04-backupvaults
    04_networking_nsgs: 04-networking-nsgs
    05_networking_vnets: 05-networking-vnets
    06_networking_dnszones: 06-networking-dnszones
    07_keyvaults: 07-keyvaults

    [*] --> 01_iam_custom_roles
    01_iam_custom_roles --> 02_iam_applications : needs roles
    02_iam_applications --> 03_resource_groups : needs SPN assignments

    03_resource_groups --> 04_backup_vaults : needs RG name
    04_backup_vaults --> [*]

    03_resource_groups --> 04_networking_nsgs : needs RG name
    03_resource_groups --> 05_networking_vnets : needs RG name
    03_resource_groups --> 06_networking_dnszones : needs RG name
    03_resource_groups --> 07_keyvaults : needs RG name

    04_networking_nsgs --> 05_networking_vnets : NSGs attached to VNet
    05_networking_vnets --> 06_networking_dnszones : private DNS zones may need VNet ID
    06_networking_dnszones --> 07_keyvaults : may need private DNS zone

    07_keyvaults --> [*]
{{< /mermaid >}}

{{< admonition note "Reminder" >}}
Remember: directories sharing the same prefix number (e.g., [04-backupvaults](https://github.com/infra-at-scale/organization-template/tree/v1.0.0/04-backupvaults) and [04-networking-nsgs](https://github.com/infra-at-scale/organization-template/tree/v1.0.0/04-networking-nsgs)) can be applied in parallel if they are not dependent on each other.
{{< /admonition >}}

#### Expanding the infrastructure

The [organization-template](https://github.com/infra-at-scale/organization-template) repository was intentionally kept small and focused. It provides a strong foundation that can be safely extended.

When adding new infrastructure areas, I recommend following the naming convention, keeping state scopes small, using [Azure Verified Modules](https://azure.github.io/Azure-Verified-Modules/) whenever possible, and passing values across modules using outputs and remote state, not hardcoded references.

### Application infrastructure

While exploring the [organization-template](https://github.com/infra-at-scale/organization-template), you might be wondering: _where should the application infrastructure go?_ Things like a virtual machine, a [Storage Account](https://learn.microsoft.com/en-us/azure/storage/common/storage-account-overview), a database, or an [Azure Function](https://learn.microsoft.com/en-us/azure/azure-functions/functions-overview). In the approach I prefer, all of these components are managed alongside the application code.

This means that the application team is fully responsible for its infrastructure, maintained within the same repository and lifecycle as the application itself. This significantly reduces delivery time and minimizes dependencies on the platform team.

<!-- 1. Description -->
In this setup, the repository's root directory contains an `infra` folder (1️⃣), which holds subdirectories for each environment the application is (or might be) deployed to, like `dev` (2️⃣) and `prod` (3️⃣). The application code itself lives in a `src` folder or any other directory that matches your language or project conventions.

<!-- 2. Example structure -->
An example project structure might look like this:

```text
app-repo
├── infra 1️⃣
│   ├── dev 2️⃣
│   │   ├── data.tf
│   │   ├── main.tf
│   │   ├── outputs.tf
│   │   └── providers.tf
│   └── prod 3️⃣
│       ├── data.tf
│       ├── main.tf
│       ├── outputs.tf
│       └── providers.tf
├── README.md
└── src
```

<!-- 3. Adding a resource -->
To add a new infrastructure resource, simply declare it inside the appropriate environment folder. To prevent configuration drift, I recommend wrapping such resources into reusable modules and placing them in a private registry. If multiple applications require the same types of infrastructure (such as a database or storage account), it's worth creating shared modules for those resources.

<!-- 4. Adding an environment -->
Onboarding a new environment is as simple as creating a new subdirectory inside the `infra` folder and calling the appropriate modules.

<!-- 5. Logic changes -->
When logic changes are needed, you create a new version of the module and gradually roll it out across environments. This mirrors the workflows used in both the [repo per service + repo per module](#repo-per-service--repo-per-module) and [monorepo + repo per module](#monorepo--repo-per-module) approaches.

<!-- 6. Maintenance -->
Ongoing maintenance is very similar to other patterns: you upgrade module or provider versions directly in each environment folder.

{{< admonition tip "Want to go deeper?" >}}
To learn more about how I build reusable modules and the infrastructure registry, check out the next article in this series: **Build flexible infrastructure modules and a lightweight registry**.
{{< /admonition >}}

#### When `organization-template` alone is enough

In some situations, separating platform infrastructure from application infrastructure may not be necessary — or even optimal.

This is especially true for organizations working on a single monolithic application that only runs in a few environments (like `dev`, `test`, and `prod`), or in cases where application teams aren't comfortable working with infrastructure code.

In these scenarios, keeping both platform and application infrastructure together in a single repository can be more practical and scalable. It simplifies onboarding, shortens deployment cycles, and lowers the barrier for the team.

### Comparison

Let's revisit the previous approaches. The table below compares **my recommended setup** with the earlier strategies.


| Approach                                                                 | Adding resources  | Environment onboarding | Refactoring | Maintenance | State size |
| ------------------------------------------------------------------------ | :---------------: | :--------------------: | :---------: | :---------: | :--------: |
| [Monorepo](#monorepo)                                                    | fast              | fast                   | hard        | hard        | large      |
| [Monorepo + local modules](#monorepo--local-modules)                     | fast              | fast                   | medium      | medium      | large      |
| [Repo per service + repo per module](#repo-per-service--repo-per-module) | fast              | slow                   | easy        | medium      | medium     |
| [Monorepo + repo per module](#monorepo--repo-per-module)                 | fast              | fast                   | easy        | medium      | large      |
| 👉 [**My approach**](#how-i-design-iac-in-azure)                             | **fast**          | **fast**               | **easy**    | **medium**  | **small**  |

The radar chart below provides a visual overview of the key differences.

{{< echarts >}}
{
  "title": {
    "text": "IaC Architecture Patterns: Complete Comparison",
    "top": "1%",
    "left": "center"
  },
  "legend": {
    "top": "90%",
    "data": [
      "Monorepo",
      "Monorepo + local modules",
      "Repo per service + repo per module",
      "Monorepo + repo per module",
      "My approach"
    ]
  },
  "radar": {
    "indicator": [
      { "name": "Adding resources", "max": 3 },
      { "name": "Environment onboarding", "max": 3 },
      { "name": "Refactoring", "max": 3 },
      { "name": "Maintenance", "max": 3 },
      { "name": "State size", "max": 3 }
    ]
  },
  "series": [
    {
      "type": "radar",
      "data": [
        {
          "value": [3, 3, 1, 1, 1],
          "name": "Monorepo"
        },
        {
          "value": [3, 3, 2, 2, 1],
          "name": "Monorepo + local modules"
        },
        {
          "value": [3, 1, 3, 2, 2],
          "name": "Repo per service + repo per module"
        },
        {
          "value": [3, 3, 3, 2, 1],
          "name": "Monorepo + repo per module"
        },
        {
          "value": [3, 3, 3, 2, 3],
          "name": "My approach"
        }
      ]
    }
  ]
}
{{< /echarts >}}

## Summary

In this article, you've explored multiple approaches to structuring Infrastructure as Code on [Microsoft Azure](https://azure.microsoft.com/) using [OpenTofu](https://opentofu.org/). From a basic monorepo to local modules, to versioned modules and service-specific repositories, each approach has its strengths and trade-offs. There is no one-size-fits-all solution. The best choice depends on your team's needs, the scale of your organization, and how you collaborate on infrastructure.

I also showed you how I personally approach this: I use the [organization-template](https://github.com/infra-at-scale/organization-template) as the core foundation and keep application infrastructure in the same repository as the app itself. This gives me scalability, clarity, and easier maintenance without taking away autonomy from application teams.

But this is just the beginning.  
In the next part of this series, I’ll walk you through how I design versioned infrastructure modules compliant with [AVM](https://azure.github.io/Azure-Verified-Modules/), and how I build a lightweight registry that makes it easy to share and scale infrastructure across teams.

{{< admonition example "What’s next?" >}}
Do you like the concept behind [`organization-template`](https://github.com/infra-at-scale/organization-template)?

👉 Use the **[Use this template](https://github.com/new?template_name=organization-template&template_owner=infra-at-scale)** button or [fork](https://github.com/infra-at-scale/organization-template/fork) the repository — and see how this skeleton works in your organization.

Have ideas for improvement?

👉 Check out the [CONTRIBUTING.md](https://github.com/infra-at-scale/organization-template/blob/v1.0.0/docs/CONTRIBUTING.md) and see how you can get involved.

Found a bug?

👉 Report an issue [here](https://github.com/infra-at-scale/organization-template/issues).
{{< /admonition >}}

{{< buymeacoffee >}}
