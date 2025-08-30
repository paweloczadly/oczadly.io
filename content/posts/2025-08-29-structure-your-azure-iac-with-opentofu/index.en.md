---
title: "Structure your Azure IaC with OpenTofu"
subtitle: "Scalable root modules and organizational patterns for real-world platforms."
date: 2025-08-29
description: "Scalable root modules and organizational patterns for real-world platforms."
draft: false
resources:
- name: "featured-image"
  src: "featured-image.png"
---

Przez lata widziałem, że firmy stosowały różne podejścia, które działały lepiej lub gorzej.
Powtórzenie golden-template struktury IaC dla firm.

## Założenia

Używamy Azure, OpenTofu oraz GitHuba. 

## Jak można zaprojektować IaC w Azure

Pomijam monorepo i chaos, bo czytelnicy bloga na pewno tak nie robią.
Monorepo + folder modules.
Repo per usługa np. tofu-storage-accounts.
Monorepo na root modules + monorepo na moduły.
Monorepo na root modules + repo per module.
Pomijam repo per usługa + mono repo na moduły oraz repo per usługa + repo per module.
Zalety + wyzwania podejść 2-5.

## Golden-template dla organizacji 

Wybieram podejście monorepo na root moduły + repo per module. Pokazuję sam szkielet folderów w monorepo na root moduły i warstwy: najpierw subskrybcje i inne “bardziej ogólne” usługi w Azure. Następnie te bardziej szczegółowe np. klastry AKS.

{{< admonition tip "Root modules generator" >}}
Wherever Microsoft and AVM do not provide official modules or coverage, I intentionally avoid wrapping infrastructure code in custom modules.

My goal is to give the user the most native and idiomatic Azure experience, aligned with AVM and ready to migrate to upstream modules once they become available.

To reduce boilerplate and improve maintainability, this repository includes simple generators for root modules — not abstractions.

You are free to:

* use the generators and customize the output,
* extract the logic into your own internal modules and registries,
* or (least recommended) copy-paste the code across root modules.

More about module registries and best practices in the upcoming blog post: "Build reusable modules and a registry. OpenTofu module best practices with versioning, examples, and internal publishing".
{{< /admonition >}}
