---
title: "Organizacja kodu infrastruktury Azure przy użyciu OpenTofu"
subtitle: "Skalowalna struktura kodu infrastruktury dla Twojej organizacji."
date: 2025-08-29
description: "Skalowalna struktura kodu infrastruktury dla Twojej organizacji."
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

{{< admonition tip "Generator root modułów" >}}
W miejscach, gdzie Microsoft i AVM nie dostarczają oficjalnych modułów ani gotowych rozwiązań, celowo unikam opakowywania kodu infrastruktury we własne moduły.

Moim celem jest dostarczenie użytkownikowi jak najbardziej natywnego i idiomatycznego doświadczenia pracy z Azure, zgodnego z AVM i gotowego do migracji na oficjalne moduły, gdy tylko się pojawią.

Aby ograniczyć powtarzalność i ułatwić utrzymanie, repozytorium zawiera proste generatory modułów root – nie abstrakcje.

Możesz:

* skorzystać z generatorów i dostosować wygenerowany kod do swoich potrzeb,
* wydzielić logikę do własnych modułów i wewnętrznych rejestrów,
* lub (najmniej rekomendowana opcja) kopiować kod między root modułami.

Więcej o budowie rejestrów i dobrych praktykach tworzenia modułów:
"Budowa reużywalnych modułów i registry. Praktyki tworzenia modułów OpenTofu z wersjonowaniem, przykładami i publikacją wewnętrzną."
{{< /admonition >}}
