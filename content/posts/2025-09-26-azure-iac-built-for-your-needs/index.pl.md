---
title: "Azure IaC zbudowana dla Twoich potrzeb"
subtitle: "Wzorce architektoniczne i gotowe narzędzia do dalszej rozbudowy — oparte na OpenTofu i AVM."
series: ["Infrastructure at scale with Azure and OpenTofu"]
date: 2025-09-26
description: "Wzorce architektoniczne i gotowe narzędzia do dalszej rozbudowy — oparte na OpenTofu i AVM."
draft: false
resources:
- name: "featured-image"
  src: "featured-image.png"
---

Przez lata pracy miałem okazję uczestniczyć w wielu projektach i widzieć różne podejścia do organizacji infrastruktury jako kod przy użyciu [Terraforma](https://developer.hashicorp.com/terraform). Niektóre z nich działały lepiej, inne gorzej. Część świetnie sprawdzała się na początku, ale w miarę rozwoju projektu — przy dodawaniu nowych zasobów pod presją czasu i priorytetów organizacji — kod stawał się trudny w utrzymaniu. Infrastruktura nadal była zapisana w kodzie, ale każda zmiana zajmowała więcej czasu, a refaktoryzacja przestawała być opłacalna.

Dzięki tym doświadczeniom wiem, jak **ja sam** chciałbym budować infrastrukturę jako kod w nowych projektach — i jak podszedłbym do migracji istniejących zasobów chmurowych do repozytoriów.

Pomyślałem też, że seria tych artykułów będzie dobrą okazją do uporządkowania wiedzy o [Microsoft Azure](https://azure.microsoft.com/) — w sposób praktyczny, z realną wartością zarówno dla mnie, jak i dla Ciebie.

Zapraszam Cię zatem do serii **"Infrastruktura w skali z Azure i OpenTofu"**. Poniżej znajdziesz listę artykułów i to, czego możesz się z nich dowiedzieć.

{{< admonition abstract "Opis serii" >}}
Ten artykuł jest częścią serii **"Infrastruktura w skali z Azure i OpenTofu"**. Całość składa się z poniższych wpisów.

- [ ] [**Azure IaC zbudowana dla Twoich potrzeb**](#) (czytasz go właśnie teraz).
  
  Poznasz podejścia do projektowania infrastruktury jako kod — ich zalety oraz ograniczenia. Zobaczysz szkielet, który możesz wdrożyć u siebie lub w swoim zespole.

- [ ] Zbuduj elastyczne moduły infrastruktury oraz ich rejestr. 

  Dowiesz się, jak tworzyć moduły [OpenTofu](https://opentofu.org/) zgodnie z dobrymi praktykami: elastyczne, wersjonowane i gotowe na współdzielenie. Pokażę też, jak uruchomić własny lekki rejestr.

- [ ] Zaprojektuj CI/CD dla kodu Twojej infrastruktury jako kod.

  Zobaczysz, jak może wyglądać skuteczne CI/CD dla Twojej infrastruktury. Omówimy narzędzia, schematy integracji i automatyzacje ułatwiające rozwój, wdrożenia i utrzymanie.

{{< /admonition >}}

## Założenia

Zanim zaczniemy, ustalmy kilka podstawowych założeń. W tej serii korzystam z:

* [Microsoft Azure](https://azure.microsoft.com/) — bo chcę przy okazji uporządkować swoją wiedzę z tej chmury, tworząc coś realnie przydatnego.
* [OpenTofu](https://opentofu.org/) — bo to w pełni open source’owa alternatywa dla [Terraforma](https://developer.hashicorp.com/terraform).
* [GitHub](https://github.com/) — bo to najczęściej wybierane narzędzie do hostowania kodu i automatyzacji CI/CD.

Choć seria koncentruje się na [Microsoft Azure](https://azure.microsoft.com/), [OpenTofu](https://opentofu.org/) i [GitHubie](https://github.com/), większość omawianych wzorców możesz zaadaptować do innych chmur, używać z [Terraformem](https://developer.hashicorp.com/terraform), [GitLabem](https://gitlab.com/) czy dowolnym innym narzędziem CI/CD.

## Jak można zaprojektować IaC w Azure

Zacznijmy od przeglądu podejść do organizowania infrastruktury jako kod w [Microsoft Azure](https://azure.microsoft.com/), z użyciem [OpenTofu](https://opentofu.org/). Pokażę Ci kilka modeli, z którymi spotkałem się w praktyce – wraz z ich zaletami i ograniczeniami.

Po tej sekcji przedstawię podejście, które sam wybrałem do tworzenia infrastruktury jako kod w moich projektach.

{{< admonition note "Uwaga" >}}
W przykładach celowo nie używam `for_each` ani `count`. Chcę, aby skupiały się one na **strukturze repozytoriów, wersjonowaniu modułów oraz granicach stanu**, a nie na detalach implementacyjnych. Te mechanizmy pojawią się w kolejnych wpisach z serii.
{{< /admonition >}}

### Monorepo

<!-- 1. Opis -->
W tym podejściu cała infrastruktura jako kod znajduje się w jednym repozytorium. Najczęściej jest ona podzielona na środowiska, na przykład `dev` (1️⃣) i `prod` (2️⃣), a w nich na katalogi, takie jak `databases` (3️⃣) czy `network` (4️⃣), w których definiuje się zasoby (`resource`) i/lub moduły (`module`). Pliki stanu zawierają wiele elementów, co z czasem utrudnia ich utrzymanie.

<!-- 2. Przykładowa struktura -->
Przykładowa struktura repozytorium w takim podejściu może wyglądać tak:

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

A tak typowe pliki środowiskowe.

* `prod/databases/main.tf`

```hcl
resource "azurerm_postgresql_flexible_server" "checkout_db" {
  /* Pozostały kod pominięty dla przejrzystości */
}

resource "azurerm_postgresql_flexible_server" "shipping_db" {
  /* Pozostały kod pominięty dla przejrzystości */
}
```

* `dev/databases/main.tf`

```hcl
resource "azurerm_postgresql_flexible_server" "checkout_db" {
  /* Pozostały kod pominięty dla przejrzystości */
}

resource "azurerm_postgresql_flexible_server" "shipping_db" {
  /* Pozostały kod pominięty dla przejrzystości */
}
```

<!-- 3. Dodawanie zasobu -->
Dodanie nowego zasobu wymaga zadeklarowania go we wszystkich odpowiednich miejscach.

<!-- 4. Onboarding środowiska -->
Wdrożenie nowego środowiska polega na utworzeniu dodatkowego folderu w monorepo i zdefiniowaniu w nim wymaganych zasobów.

<!-- 5. Zmiany w logice -->
Dodawanie nowych funkcjonalności lub refaktoryzacja często wiążą się ze zmianami w wielu miejscach – zarówno w ramach jednego środowiska, jak i pomiędzy nimi. Ten rozproszony zakres zmian zwiększa nakład pracy, przez co takie inicjatywy często nie są realizowane.

<!-- 6. Utrzymanie -->
Podbijanie wersji providerów lub modułów wymaga modyfikacji w wielu folderach jednocześnie, co zniechęca do bieżącej aktualizacji i zwiększa ryzyko zaległości technicznych.

<!-- 7. Zalety i ograniczenia -->
#### Zalety i ograniczenia

✅ **Szybki start**. Idealne na proof of concept lub krótkie eksperymenty.

❌ **Chaos przy większej skali**. Wzrost liczby zasobów utrudnia utrzymanie i aktualizacje.

❌ **Duży stan**. Duże pliki stanu spowalniają pracę i utrudniają wdrażanie zmian.

<!-- 8. Kiedy wybrać? -->
{{< admonition question "Kiedy wybrać?" >}}
Moim zdaniem: _tylko dla bardzo małych projektów lub własnych eksperymentów. W przypadku produkcyjnych rozwiązań zdecydowanie je odradzam._
{{< /admonition >}}

---

### Monorepo + lokalne moduły

<!-- 1. Opis -->
W tym podejściu zasoby definiowane są jako lokalne moduły. Repozytorium zawiera katalog `modules` (1️⃣), w którym znajdują się wersjonowane moduły infrastrukturalne. Każde środowisko (np. `dev` (2️⃣), `prod` (3️⃣)) posiada osobne katalogi z plikami stanu, które wykorzystują te moduły.

Pliki stanu nadal obejmują wiele zasobów, co z czasem utrudnia pracę i ogranicza niezależność zmian.

<!-- 2. Przykładowa struktura -->
W praktyce wygląda to tak, jak poniżej:

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

A tak typowe wywołanie modułów.

* `environments/prod/databases/main.tf`:

```hcl
module "checkout_db" {
  source = "../../../modules/database-1.0"

  /* Pozostały kod pominięty dla przejrzystości */
}

module "shipping_db" {
  source = "../../../modules/database-1.0"

  /* Pozostały kod pominięty dla przejrzystości */
}

/* Pozostały kod pominięty dla przejrzystości */
```

* `environments/dev/databases/main.tf`:

```hcl
module "checkout_db" {
  source = "../../../modules/database-1.1"

  /* Pozostały kod pominięty dla przejrzystości */
}

module "shipping_db" {
  source = "../../../modules/database-1.2"

  /* Pozostały kod pominięty dla przejrzystości */
}

/* Pozostały kod pominięty dla przejrzystości */
```

<!-- 3. Dodawanie zasobu -->
Dodanie kolejnych zasobów polega zazwyczaj na ponownym wywołaniu istniejącego modułu. Dzięki temu kod jest mniej zduplikowany – powtarzają się jedynie deklaracje modułów.

<!-- 4. Onboarding środowiska -->
Wdrożenie nowego środowiska wymaga utworzenia katalogu i dodania w nim wywołań lokalnych modułów.

<!-- 5. Zmiany w logice -->
Gdy potrzebna jest zmiana w module albo jego refaktoryzacja, tworzy się nowy katalog z nową wersją (np. `database-1.1`) i tam wprowadza modyfikacje. Jednak przy rosnącej liczbie wersji modułów i aplikacji, z czasem narasta dług techniczny związany z testowaniem oraz utrzymywaniem zgodności między wersjami.

<!-- 6. Utrzymanie -->
Aktualizacja wersji providerów lub modułów nadal wymaga zmian w wielu miejscach jednocześnie, ale dzięki modularności jest to bardziej kontrolowalne niż wcześniej. Jeżeli chcemy zachować jednolitą wersję modułu we wszystkich środowiskach, trzeba zaktualizować każdą referencję.

<!-- 7. Zalety i ograniczenia -->
#### Zalety i ograniczenia

✅ **Lepsze współdzielenie logiki**. Lokalne moduły można ponownie używać, co sprzyja standaryzacji.

✅ **Większa czytelność niż w czystym monorepo**. Katalog `modules` tworzy pewną strukturę.

❌ **Fałszywe poczucie porządku**. Użycie modułów sprawia wrażenie dobrej architektury, ale bez jasnych konwencji projekt może się szybko skomplikować.

❌ **Koszt aktualizacji i testowania**. Aktualizacje wersji to wielokrotne zmiany i konieczność utrzymania wielu wersji lokalnego modułu zanim nowa wersja zostanie dodana we wszystkich miejscach.

❌ **Wciąż zbyt wiele zasobów w jednym stanie**. Pliki stanu są nadal zbyt obszerne, co utrudnia równoległy rozwój.

<!-- 8. Kiedy wybrać? -->
{{< admonition question "Kiedy wybrać?" >}}
Moim zdaniem: _dla bardzo małych zespołów i niewielkiej infrastruktury to rozwiązanie może sprawdzać się nawet w środowisku produkcyjnym. Przy większej skali utrzymywanie wielu wersji lokalnych modułów szybko staje się uciążliwe._
{{< /admonition >}}

---

### Repo per usługa + repo per module

<!-- 1. Opis -->
To podejście jest przeciwieństwem monorepo. Przypomina to architekturę mikroserwisów: każda część jest izolowana i zarządzana osobno. Każde repozytorium odpowiada za konkretną usługę lub obszar infrastruktury — np. `tofu-networking` dla sieci, `tofu-databases` dla warstwy danych (1️⃣). Wewnątrz każdego z nich znajdują się katalogi środowiskowe — np. `dev` (2️⃣) i `prod` (3️⃣).

Repozytoria zawierają wywołania modułów, natomiast sama logika tworzenia zasobów znajduje się w osobnych repozytoriach z modułami — np. [terraform-azurerm-avm-res-resources-resourcegroup](https://github.com/Azure/terraform-azurerm-avm-res-resources-resourcegroup) z [Azure Verified Modules](https://azure.github.io/Azure-Verified-Modules/) lub w prywatnym rejestrze w Twojej organizacji. Moduły mogą być wywoływane z rejestru (po wersji) lub bezpośrednio z repozytorium (po commicie lub tagu), zgodnie z [dokumentacją OpenTofu](https://opentofu.org/docs/language/modules/sources/).

Można też trzymać moduły lokalnie — w katalogu `modules` wewnątrz repozytorium usługi. Warto jednak pamiętać o ich ograniczeniach opisanych wcześniej.

Chociaż same repozytoria są mniejsze, pliki stanu często obejmują wiele zasobów — co z czasem może utrudniać utrzymanie.

<!-- 2. Przykładowa struktura -->
Przykładowa struktura repozytorium dla warstwy baz danych:

```text
tofu-databases 1️⃣
├── dev 2️⃣
│   ├── main.tf
│   └── providers.tf
└── prod 3️⃣
    ├── main.tf
    └── providers.tf
```

Typowe pliki środowiskowe:

* `prod/main.tf`:

```hcl
module "checkout_db" {
  source  = "modules.example.net/database/azurerm"
  version = "1.0.0"

  /* Pozostały kod pominięty dla przejrzystości */
}

module "shipping_db" {
  source  = "modules.example.net/database/azurerm"
  version = "1.0.0"

  /* Pozostały kod pominięty dla przejrzystości */
}

/* Pozostały kod pominięty dla przejrzystości */
```

* `dev/main.tf`:

```hcl
module "checkout_db" {
  source  = "modules.example.net/database/azurerm"
  version = "1.1.0"

  /* Pozostały kod pominięty dla przejrzystości */
}

module "shipping_db" {
  source  = "modules.example.net/database/azurerm"
  version = "1.2.0"

  /* Pozostały kod pominięty dla przejrzystości */
}

/* Pozostały kod pominięty dla przejrzystości */
```

<!-- 3. Dodawanie zasobu -->
Dodawanie nowych zasobów przez moduły jest szybkie. Mniejsze repozytoria ograniczają konflikty i blokowanie pracy — typowe problemy dużego monorepo.

<!-- 4. Onboarding środowiska -->
Trzeba jednak pamiętać, że duża liczba repozytoriów dedykowanych konkretnym usługom może być uciążliwa przy tworzeniu nowych środowisk. W takim przypadku w każdym z tych repozytoriów trzeba utworzyć pull request z dodaniem nowego folderu środowiska.

<!-- 5. Zmiany w logice -->
Zmiany w module nie wpływają bezpośrednio na kod repozytorium usługi, co upraszcza rozwój i testowanie. Trzeba jednak uważać na zależności — jeśli moduł A udostępnia outputy wykorzystywane przez moduł B, zmiana outputów wymaga odświeżenia stanu modułu zależnego.

Warto zadbać o CI/CD dla modułów, co przyspiesza ich rozwój i poprawia jakość.

<!-- 6. Utrzymanie -->
Utrzymanie wymaga dyscypliny. Wersje modułów i providerów trzeba aktualizować w wielu repozytoriach. Automatyzacja (np. Renovate) i jasne praktyki zespołowe znacząco to ułatwiają.

<!-- 7. Zalety i ograniczenia -->
#### Zalety i ograniczenia

✅ **Niski próg wejścia**. Dzięki niewielkim rozmiarom repozytoriów, nowy inżynier szybko zrozumie, za co odpowiada konkretne repo.

✅ **Bezpieczna refaktoryzacja**. Zmiany logiczne nie wpływają bezpośrednio na stan środowisk. Można testować osobno.

❌ **Złożony onboarding środowiska**. Dodanie nowego środowiska wymaga zmian w wielu repozytoriach (i wielu PR-ach).

❌ **Rosnący stan**. Duże pliki stanu nadal ograniczają pracę równoległą i spowalniają plan / apply.

<!-- 8. Kiedy wybrać? -->
{{< admonition question "Kiedy wybrać?" >}}
Moim zdaniem: _dla większych zespołów i bardziej rozbudowanej infrastruktury, szczególnie gdy nie zachodzi potrzeba częstego dodawania i usuwania środowisk. Warto zadbać o CI/CD dla modułów oraz automatyzację aktualizacji wersji._
{{< /admonition >}}

---

### Monorepo + repo per module

<!-- 1. Opis -->
Podejście łączące centralizację root modułów z wersjonowaniem logiki infrastruktury w osobnych repozytoriach modułów. Root moduły, zawierające pliki stanu, znajdują się w jednym repozytorium. Typowo struktura jest podzielona według środowisk (`dev` (1️⃣), `prod` (2️⃣), itd.). Wewnątrz każdego z nich znajdują się katalogi definiujące obszary infrastruktury - np. `databases` (3️⃣) i `network` (4️⃣).

Moduły infrastrukturalne umieszczone są w osobnych repozytoriach – jak w poprzednim podejściu – i mogą być wywoływane ze zdalnego rejestru (z określoną wersją) lub bezpośrednio z repozytorium (poprzez commit lub tag).

Dzięki centralizacji plików stanu, koordynacja wdrożeń między zespołami jest łatwiejsza. Jednak pliki stanu nadal często obejmują wiele zasobów, co może utrudniać niezależny rozwój i testowanie.

<!-- 2. Przykładowa struktura -->
Przykładowa struktura jest podobna do już wcześniej przedstawionych. Może wyglądać następująco:

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

Typowe wywołania modułów w środowiskach wyglądają następująco:

* `prod/databases/main.tf`:

```hcl
module "checkout_db" {
  source  = "modules.example.net/database/azurerm"
  version = "1.0.0"

  /* Pozostały kod pominięty dla przejrzystości */
}

module "shipping_db" {
  source  = "modules.example.net/database/azurerm"
  version = "1.0.0"

  /* Pozostały kod pominięty dla przejrzystości */
}

/* Pozostały kod pominięty dla przejrzystości */
```

* `dev/databases/main.tf`:

```hcl
module "checkout_db" {
  source  = "modules.example.net/database/azurerm"
  version = "1.1.0"

  /* Pozostały kod pominięty dla przejrzystości */
}

module "shipping_db" {
  source  = "modules.example.net/database/azurerm"
  version = "1.2.0"

  /* Pozostały kod pominięty dla przejrzystości */
}

/* Pozostały kod pominięty dla przejrzystości */
```

<!-- 3. Dodawanie zasobu -->
Dodawanie kolejnych zasobów, podobnie jak w monorepo z lokalnymi modułami, polega zazwyczaj na ponownym wywołaniu istniejącego modułu. Dzięki modularności unika się powielania logiki.

<!-- 4. Onboarding środowiska -->
Dodanie nowego środowiska polega na utworzeniu folderu w strukturze katalogów oraz inicjalizacji backendu stanu. Dzięki centralizacji wszystko znajduje się w jednym repozytorium, co przyspiesza onboarding — o ile struktura katalogów jest dobrze zorganizowana.

<!-- 5. Zmiany w logice -->
Zmiany w module wymagają utworzenia nowej wersji (np. 1.1.0) i jej wdrożenia w konkretnym katalogu środowiskowym. Dzięki temu dodawanie nowych funkcjonalności lub przeprowadzanie refaktoryzacji jest proste do zrobienia. Należy jednak pamiętać o CI/CD dla modułów, które ułatwią dostarczanie.

<!-- 6. Utrzymanie -->
Utrzymanie jest umiarkowanie złożone. Wersjonowanie modułów zapewnia przewidywalność zmian. Jednocześnie centralizacja stanu może sprawić, że zmiany w komponentach wspólnych (np. aktualizacja providera) będą miały szerszy zasięg i wymagają większej uwagi przy testowaniu.

<!-- 7. Zalety i ograniczenia -->
#### Zalety i ograniczenia

✅ **Jedno źródło prawdy**. Wszyscy widzą całość infrastruktury w jednym miejscu.

✅  **Prostszy onboarding środowiska**. Dodanie nowego środowiska (np. `trial` lub `test`) wymaga jedynie stworzenia nowego folderu w monorepo i dodaniu wywołań potrzebnych modułów.

✅ **Prostszy rozwój i utrzymanie**. Dodawanie nowej logiki lub refaktoryzacja istniejącego kodu są bezpieczniejsze i bardziej komfortowe.

❌ **Zbyt duże pliki stanu**. Centralizacja stanu może skutkować konfliktem przy zmianach, wolniejszym plan i problemami z równoległym developmentem.

<!-- 8. Kiedy wybrać? -->
{{< admonition question "Kiedy wybrać?" >}}
Moim zdaniem: _To podejście może sprawdzić się dobrze w średnich oraz dużych zespołach, które chcą zachować centralne repozytorium, ale korzystać z elastyczności i wersjonowania modułów. Wymaga dobrej dyscypliny w strukturze folderów, CI/CD dla modułów oraz automatyzacji aktualizacji wersji._
{{< /admonition >}}

---

### Porównanie

Podsumowując tą sekcję, zestawiłem wszystkie podejścia w jednej tabeli, aby ułatwić dobór strategii dopasowanej do specyfiki zespołu, skali środowiska oraz sposobu zarządzania infrastrukturą.

| Podejście                                                              | Dodawanie zasobów | Onboarding środowiska | Refactoring | Utrzymanie | Wielkość stanu |
| ---------------------------------------------------------------------- | :---------------: | :-------------------: | :---------: | :--------: | :------------: |
| [Monorepo](#monorepo)                                                  | szybkie           | szybki                | trudny      | trudne     | duża           |
| [Monorepo + lokalne moduły](#monorepo--lokalne-moduły)                 | szybkie           | szybki                | średni      | średnie    | duża           |
| [Repo per usługa + repo per module](#repo-per-usługa--repo-per-module) | szybkie           | wolny                 | łatwy       | średnie    | średnia        |
| [Monorepo + repo per module](#monorepo--repo-per-module)               | szybkie           | szybki                | łatwy       | średnie    | duża           |

Poniższy diagram radarowy wizualizuje kluczowe cechy każdego podejścia, ułatwiając wybór najlepiej dopasowanej strategii.

{{< echarts >}}
{
  "title": {
    "text": "Wzorce architektury IaC – porównanie",
    "top": "1%",
    "left": "center"
  },
  "legend": {
    "top": "90%",
    "data": [
      "Monorepo",
      "Monorepo + lokalne moduły",
      "Repo per usługa + repo per module",
      "Monorepo + repo per module"
    ]
  },
  "radar": {
    "indicator": [
      { "name": "Dodawanie zasobów", "max": 3 },
      { "name": "Onboarding środowiska", "max": 3 },
      { "name": "Refactoring", "max": 3 },
      { "name": "Utrzymanie", "max": 3 },
      { "name": "Wielkość stanu", "max": 3 }
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
          "name": "Monorepo + lokalne moduły"
        },
        {
          "value": [3, 1, 3, 2, 2],
          "name": "Repo per usługa + repo per module"
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

## Jak ja projektuję IaC w Azure


Po omówieniu różnych strategii organizacji infrastruktury jako kodu, czas pokazać strukturę wykorzystywaną przeze mnie — skalowalną, modularną i zgodną z [Azure Verified Modules](https://azure.github.io/Azure-Verified-Modules/). Bazuje ona na podejściu [Monorepo + repo per module](#monorepo--repo-per-module), ale została wzbogacona o kilka istotnych niuansów.

Całość dzieli się na dwie części:

* Core
* Infrastruktura aplikacji

W kolejnych sekcjach opisuję szczegółowo każdą z nich.

### Core: `organization-template`

Część monorepo nazywam [organization-template](https://github.com/infra-at-scale/organization-template) i traktuję jako solidny punkt wyjścia dla każdej organizacji — niezależnie od skali czy złożoności. Znajdziesz tam gotowy do użycia kod [OpenTofu](https://opentofu.org/) oparty o [Azure Verified Modules](https://azure.github.io/Azure-Verified-Modules/), który pomoże Ci stworzyć fundamenty dla Twojej organizacji w [Microsoft Azure](https://azure.microsoft.com/).

#### Zawartość

W skład [organization-template](https://github.com/infra-at-scale/organization-template) wchodzą między innymi:

* Definicja roli IAM oraz aplikacji w [Microsoft Entra ID](https://www.microsoft.com/security/business/microsoft-entra).
* Definicja [Resource Groups](https://learn.microsoft.com/en-us/azure/azure-resource-manager/management/manage-resource-groups-portal#what-is-a-resource-group) potrzebnych w Twoich [Subscriptions](https://learn.microsoft.com/en-us/microsoft-365/enterprise/subscriptions-licenses-accounts-and-tenants-for-microsoft-cloud-offerings?view=o365-worldwide#subscriptions).
* Definicja warstwy sieciowej dla Twoich aplikacji.

Struktura jest prosta: czytelna, łatwa w utrzymaniu i gotowa do rozbudowy.

#### Konwencja nazewnicza

W głównym katalogu znajdują się katalogi odpowiedzialne za poszczególne obszary infrastruktury. Nazwane są zgodnie z poniższą konwencją:

{{< raw >}}
<center>
<span style="font-size: 2em; font-weight:600;">
<span style="color:#bcb908;">${nn}</span>-<span style="color:#765306;">${optional-area}</span>-<span style="color:#718051;">${azure-service}</span>
</span>
</center>
{{< /raw >}}

Na przykład:

* [02-iam-applications](https://github.com/infra-at-scale/organization-template/tree/v1.0.0/02-iam-applications)
* [03-resourcegroups](https://github.com/infra-at-scale/organization-template/tree/v1.0.0/03-resourcegroups)

Jeżeli dwa lub więcej katalogów mają ten sam numer, na przykład [04-backupvaults](https://github.com/infra-at-scale/organization-template/tree/v1.0.0/04-backupvaults) i [04-networking-nsgs](https://github.com/infra-at-scale/organization-template/tree/v1.0.0/04-networking-nsgs) mogą być wykonywane równolegle, ponieważ nie mają między sobą zależności.

Dzięki tej konwencji nazewniczej w głównym katalogu od razu wiadomo, jaka jest kolejność wykonywania. Taka numeracja i struktura katalogów pozwala z jednej strony jasno odczytać kolejność, a z drugiej — umożliwia równoległe wykonywanie części modułów, co skraca czas wdrożeń.

W przypadku rozbudowy o kolejne obszary dodaje się nowy katalog z odpowiednią numeracją, w razie potrzeby zmieniając istniejącą numerację. Jeżeli poszczególne obszary nie są od siebie zależne mogą być umieszczane na tym samym poziomie poprzez dodanie tego samego numeru.

#### Hierarchia

Każdy obszar infrastruktury ma odpowiednią hierarchię:

{{< raw >}}
<center>
<span style="font-size: 1.5em; font-weight:600;">
<span style="color:#bcb908;">${area}</span>/<span style="color:#765306;">${optional-subscription-name}</span>/<span style="color:#718051;">${optional-resources-group-name}</span>/<span style="color:#e4d297ff;">${root-module}</span>
</span>
</center>
{{< /raw >}}


Na przykład:

* [02-iam-applications/github-actions](https://github.com/infra-at-scale/organization-template/tree/v1.0.0/02-iam-applications/github-actions) – aplikacje w [Microsoft Entra ID](https://www.microsoft.com/security/business/microsoft-entra) nie są przypisane do [Subscription](https://learn.microsoft.com/en-us/microsoft-365/enterprise/subscriptions-licenses-accounts-and-tenants-for-microsoft-cloud-offerings?view=o365-worldwide#subscriptions) ani [Resource Group](https://learn.microsoft.com/en-us/azure/azure-resource-manager/management/manage-resource-groups-portal#what-is-a-resource-group) dlatego oba parametry są pominięte.
* [03-resourcegroups/your-subscription/rg-default-eastus](https://github.com/infra-at-scale/organization-template/tree/v1.0.0/03-resourcegroups/your-subscription/rg-default-eastus) – ponieważ [Resource Group'a](https://learn.microsoft.com/en-us/azure/azure-resource-manager/management/manage-resource-groups-portal#what-is-a-resource-group) `rg-default-eastus` należy do [Subscription](https://learn.microsoft.com/en-us/microsoft-365/enterprise/subscriptions-licenses-accounts-and-tenants-for-microsoft-cloud-offerings?view=o365-worldwide#subscriptions) `dev`, tylko `${optional-subscription-name}` jest zdefiniowane.
* [05-networking-vnets/your-subscription/rg-default-eastus/vnet-default-eastus](https://github.com/infra-at-scale/organization-template/tree/v1.0.0/05-networking-vnets/your-subscription/rg-default-eastus/vnet-default-eastus) – ponieważ [Azure Virtual Network](https://learn.microsoft.com/en-us/azure/virtual-network/virtual-networks-overview) `vnet-default-eastus` należy do [Resource Group'y](https://learn.microsoft.com/en-us/azure/azure-resource-manager/management/manage-resource-groups-portal#what-is-a-resource-group) `dev`, która z kolei należy do [Subscription](https://learn.microsoft.com/en-us/microsoft-365/enterprise/subscriptions-licenses-accounts-and-tenants-for-microsoft-cloud-offerings?view=o365-worldwide#subscriptions) `dev`, zdefiniowane są zarówno `${optional-resources-group-name}`, jak i `${optional-subscription-name}`.

Hierarchia ta nawiązuje do konwencji nazewniczej zasobów w [Microsoft Azure](https://azure.microsoft.com/). Na przykład:

```text
/subscriptions/${subscription-id}/resourceGroups/rg-default-eastus/providers/Microsoft.Network/virtualNetworks/vnet-default-eastus
```

Ułatwia to nawigację po strukturze katalogów.

W podejściu, które preferuję stany są mniejsze. Na przykład każdy [VNet](https://learn.microsoft.com/en-us/azure/virtual-network/virtual-networks-overview) ma swój osobny stan.

Dzięki temu zmiany są szybsze do wprowadzenia, a przy okazji kod jest łatwiejszy do zrozumienia. Mniejsze stany ułatwiają też równoległe wdrażanie i uniknięcie konfliktów między zespołami.

Ponadto, ścieżki do stanów w [Storage Account](https://learn.microsoft.com/en-us/azure/storage/common/storage-account-overview) odpowiadają ścieżką w projekcie. Na przykład dla [03-resourcegroups/your-subscription/rg-default-eastus](https://github.com/infra-at-scale/organization-template/tree/v1.0.0/03-resourcegroups/your-subscription/rg-default-eastus) wygląda to następująco:

```hcl
terraform {
  backend "azurerm" {
    key = "03-resourcegroups/your-subscription/rg-default-eastus/terraform.tfstate"
    /* Pozostały kod pominięty dla przejrzystości */
  }
}
```

#### Zawartość root modułu

Root moduł to katalog, który inicjuje backend stanu (`terraform` block) i zarządza konkretnym zestawem zasobów. Typowo zawiera on pliki takie jak:

* `data.tf` – data lookups oraz wykorzystanie remote states z innych root modułów.
* `locals.tf` - powtarzalne wartości są definiowane tutaj.
* `main.tf` - wywołanie modułów i/lub tworzenie zasobów.
* `outputs.tf` - zwracanie wartości potrzebne w innych root modułach.
* `providers.tf` - deklaracja providerów oraz remote state.

Root moduły do nadawania nazw zasobą wykorzystują moduł [naming](https://registry.terraform.io/modules/Azure/naming/azurerm/latest), który generuje zgodne z konwencją nazwy zasobów w [Microsoft Azure](https://azure.microsoft.com/). Dla zasobów, które nie są aktualnie wspierane w tym module nazwy są tworzone zgodnie z [zaleceniami dotyczącymi skrótów dla zasobów platformy Azure](https://learn.microsoft.com/en-us/azure/cloud-adoption-framework/ready/azure-best-practices/resource-abbreviations).

Do tego w root modułach wykorzystane są [Azure Verified Modules](https://azure.github.io/Azure-Verified-Modules/). Na przykład [05-networking-vnets/your-subscription/rg-default-eastus/vnet-default-eastus](https://github.com/infra-at-scale/organization-template/tree/v1.0.0/05-networking-vnets/your-subscription/rg-default-eastus/vnet-default-eastus) korzysta z [avm-res-network-virtualnetwork](https://registry.terraform.io/modules/Azure/avm-res-network-virtualnetwork/azurerm/latest), a jego kod wygląda tak, jak poniżej:

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
  /* Pozostały kod pominięty dla przejrzystości */
}
```

Świadomie nie tworzę własnych wrapperów modułowych w miejscach, gdzie istniejące zasoby są proste lub istnieje perspektywa pojawienia się oficjalnego modułu [AVM](https://azure.github.io/Azure-Verified-Modules/).

Moim celem jest dostarczenie użytkownikowi jak najbardziej natywnego i idiomatycznego doświadczenia pracy z [Microsoft Azure](https://azure.microsoft.com/), zgodnego z [AVM](https://azure.github.io/Azure-Verified-Modules/) i gotowego do migracji na oficjalne moduły, gdy tylko się pojawią.

#### Zależności między root modułami

Jak już pewnie zdążyłeś zauważyć, root moduły zamiast hardkodować wartości argumentów używają wartości zwróconych z innych root modułów. Na przykład:

```hcl
# Resource group name can be used from other module via remote state:
resource_group_name = data.terraform_remote_state.rg_default_eastus.outputs.resource.name
```

Dzieje się to użyciu remote state file, jak poniżej:

```hcl
data "terraform_remote_state" "rg_default_eastus" {
  backend = "azurerm"
  config = {
    key = "03-resourcegroups/your-subscription/rg-default-eastus/terraform.tfstate"
    /* Pozostały kod pominięty dla przejrzystości */
  }
}
```

Oraz dzięki zadeklarowaniu outputów w innym root module. Na przykład w root module [03-resourcegroups/your-subscription/rg-default-eastus](https://github.com/infra-at-scale/organization-template/tree/v1.0.0/03-resourcegroups/your-subscription/rg-default-eastus):

```hcl
output "resource" {
  value = module.rg.resource
}
```

#### Kolejność wykonania

Skoro już poznałeś zawartość [organization-template](https://github.com/infra-at-scale/organization-template), konwencję nazewniczą, hierarchię, zawartość root modułów i zależności między nimi, pora przejść do tworzenia faktycznych zasobow. Root moduły powinny być uruchamiane zgodnie z ich numeracją w katalogu głównym projektu. Numeracja ta odzwierciedla zależności między modułami i pozwala na równoległe wykonanie tych, które ich nie mają.

Poniższy diagram stanów pokazuje zależności i kolejności wykonania root modułów.

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
    01_iam_custom_roles --> 02_iam_applications : potrzebuje roles
    02_iam_applications --> 03_resource_groups : potrzebuje SPN assignments

    03_resource_groups --> 04_backup_vaults : potrzebuje RG name
    04_backup_vaults --> [*]

    03_resource_groups --> 04_networking_nsgs : potrzebuje RG name
    03_resource_groups --> 05_networking_vnets : potrzebuje RG name
    03_resource_groups --> 06_networking_dnszones : potrzebuje RG name
    03_resource_groups --> 07_keyvaults : potrzebuje RG name

    04_networking_nsgs --> 05_networking_vnets : NSGs dołączona do sieci
    05_networking_vnets --> 06_networking_dnszones : private DNS zones mogą potrzebowac VNet ID
    06_networking_dnszones --> 07_keyvaults : moze potrzebowac private DNS zone

    07_keyvaults --> [*]
{{< /mermaid >}}

{{< admonition note "Przypomnienie" >}}
Dla przypomnienia, katalogi o tym samym numerze (np. [04-backupvaults](https://github.com/infra-at-scale/organization-template/tree/v1.0.0/04-backupvaults) i [04-networking-nsgs](https://github.com/infra-at-scale/organization-template/tree/v1.0.0/04-networking-nsgs)) mogą być wykonywane równolegle, ponieważ nie mają między sobą zależności.
{{< /admonition >}}

#### Rozbudowa infrastruktury

Projekt [organization-template](https://github.com/infra-at-scale/organization-template) został celowo zaprojektowany jako niewielki i zwięzły — stanowi fundament, który można bezpiecznie rozbudowywać. W przypadku chęci dodawania kolejnych obszarów infrastruktury zachęcam Cię do podążania za konwencją nazewniczą, tworzenia niedużych stanów, używania [Azure Verified Modules](https://azure.github.io/Azure-Verified-Modules/) tam, gdzie to możliwe oraz przekazywania wartości z jednego modułu do drugiego przy pomocy outputów i remote state.

### Infrastruktura aplikacji

Przeglądając [organization-template](https://github.com/infra-at-scale/organization-template) może pojawić się pytanie: _gdzie umieścić infrastrukturę aplikacji?_ Na przykład maszynę wirtualną, [Storage Account](https://learn.microsoft.com/en-us/azure/storage/common/storage-account-overview), bazę danych, [Azure Function](https://learn.microsoft.com/en-us/azure/azure-functions/functions-overview). Te wszystkie komponenty w podejściu, które preferuję są utrzymywane razem z kodem aplikacji.

Dzięki temu zespół aplikacyjny samodzielnie zarządza swoją infrastrukturą — we wspólnym repozytorium i cyklu życia, obok kodu aplikacji. To skraca czas dostarczania i minimalizuje zależności od zespołu platformowego.

<!-- 1. Opis -->

W tym podejściu w głównym folderze repozytorium znajduje się katalog `infra` (1️⃣), który zawiera podkatalogi ze środowiskami, gdzie aplikacja jest (lub może być zdeployowana). Na przykład `dev` (2️⃣) i `prod` (3️⃣). Kod aplikacji znajduje się natomiast w katalogu `src` lub innym zgodnym z Twoją konwencją lub konwencją danego języka programowania.

<!-- 2. Przykładowa struktura -->
Przykładowa struktura w takim przypadku wygląda, jak poniżej:

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

<!-- 3. Dodawanie zasobu -->
Dodawanie nowego zasobu do aplikacji wiąże się z dodaniem go w poszczególnych katalogach środowisk. Aby uniknąć zjawiska "configuration drift", warto opakować zasoby w moduły i umieścić je w prywatnym rejestrze. Jeśli kilka aplikacji potrzebuje tych samych zasobów np. bazy danych oraz storage account, warto jest stworzyć dla nich wspólny moduł.

<!-- 4. Onboarding środowiska -->
Dodawanie nowego środowiska wymaga stworzenia nowego folderu w katalogu `infra`, a następnie wywołania odpowiednich modułów.

<!-- 5. Zmiany w logice -->
Jeżeli jest potrzeba zmian w logice, tworzy się nową wersję modułu, a następnie wdraża się ją stopniowo do wszystkich środowisk. Tak samo, jak w podejściach [repo per usługa + repo per module](#repo-per-usługa--repo-per-module) albo [monorepo + repo per module](#monorepo--repo-per-module).

<!-- 6. Utrzymanie -->
Utrzymanie również przypomina poprzednie podejścia — aktualizacje wersji modułów lub providerów są wykonywane bezpośrednio w katalogach środowisk.

{{< admonition tip "Chcesz więcej?" >}}
Żeby dowiedzieć się więcej o tych modułach oraz o rejestrze zapraszam Cię do kolejnego artykułu z tej serii: **Zbuduj elastyczne moduły infrastruktury oraz ich rejestr**.
{{< /admonition >}}

#### Gdy `organization-template` wystarczy

W niektórych przypadkach oddzielenie głównej infrastruktury od infrastruktury aplikacyjnej nie jest konieczne — ani optymalne. Dotyczy to zwłaszcza organizacji, które rozwijają jedną, monolityczną aplikację wdrażaną na kilku środowiskach (np. `dev`, `test`, `prod`), lub takich, gdzie zespoły aplikacyjne nie czują się swobodnie w pracy z kodem infrastruktury.

W takich sytuacjach bardziej praktycznym i skalowalnym podejściem może być trzymanie całej infrastruktury — zarówno platformowej, jak i aplikacyjnej — w jednym repozytorium. Upraszcza to zarządzanie, przyspiesza wdrożenia i zmniejsza próg wejścia dla zespołu.

### Porównanie

Wracając do wcześniejszych podejść, poniżej przedstawiam tabelę porównującą moje podejście z poprzednimi.

| Podejście                                                              | Dodawanie zasobów | Onboarding środowiska | Refactoring | Utrzymanie | Wielkość stanu |
| ---------------------------------------------------------------------- | :---------------: | :-------------------: | :---------: | :--------: | :------------: |
| [Monorepo](#monorepo)                                                  | szybkie           | szybki                | trudny      | trudne     | duża           |
| [Monorepo + lokalne moduły](#monorepo--lokalne-moduły)                 | szybkie           | szybki                | średni      | średnie    | duża           |
| [Repo per usługa + repo per module](#repo-per-usługa--repo-per-module) | szybkie           | wolny                 | łatwy       | średnie    | średnia        |
| [Monorepo + repo per module](#monorepo--repo-per-module)               | szybkie           | szybki                | łatwy       | średnie    | duża           |
| 👉 [**Moje podejście**](#jak-ja-projektuję-iac-w-azure)                | **szybkie**       | **szybki**            | **łatwy**   | **średnie**    | **mały**       |

Poniższy diagram radarowy ilustruje te różnice w sposób wizualny.

{{< echarts >}}
{
  "title": {
    "text": "Porównanie podejść IaC z organization-template",
    "top": "1%",
    "left": "center"
  },
  "legend": {
    "top": "90%",
    "data": [
      "Monorepo",
      "Monorepo + lokalne moduły",
      "Repo per usługa + repo per module",
      "Monorepo + repo per module",
      "Moje podejście"
    ]
  },
  "radar": {
    "indicator": [
      { "name": "Dodawanie zasobów", "max": 3 },
      { "name": "Onboarding środowiska", "max": 3 },
      { "name": "Refactoring", "max": 3 },
      { "name": "Utrzymanie", "max": 3 },
      { "name": "Wielkość stanu", "max": 3 }
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
          "name": "Monorepo + lokalne moduły"
        },
        {
          "value": [3, 1, 3, 2, 2],
          "name": "Repo per usługa + repo per module"
        },
        {
          "value": [3, 3, 3, 2, 1],
          "name": "Monorepo + repo per module"
        },
        {
          "value": [3, 3, 3, 2, 3],
          "name": "Moje podejście"
        }
      ]
    }
  ]
}
{{< /echarts >}}

## Podsumowanie

W tym wpisie poznałeś różne podejścia do organizowania infrastruktury jako kod na platformie [Microsoft Azure](https://azure.microsoft.com/) przy użyciu [OpenTofu](https://opentofu.org/). Od prostego monorepo, przez lokalne moduły, aż po wersjonowane moduły i repozytoria per usługa — każde z nich ma swoje zalety i ograniczenia. Nie istnieje rozwiązanie uniwersalne. Wybór zależy od potrzeb zespołu, skali organizacji i sposobu pracy.

Pokazałem Ci też, jak sam podchodzę do tego tematu: używam [organization-template](https://github.com/infra-at-scale/organization-template) jako fundamentu, a infrastrukturę aplikacyjną trzymam bezpośrednio w repozytorium aplikacji. To połączenie daje skalowalność, przejrzystość i prostsze utrzymanie — bez odbierania zespołom aplikacyjnym autonomii.

To jednak dopiero początek. W kolejnej części tej serii pokażę, jak tworzę wersjonowane moduły zgodne z [AVM](https://azure.github.io/Azure-Verified-Modules/) oraz jak buduję lekki rejestr, który upraszcza współdzielenie i rozwój infrastruktury między zespołami.

{{< admonition example "Co dalej?" >}}
Spodobał Ci się koncept [`organization-template`](https://github.com/infra-at-scale/organization-template)?

👉 Skorzystaj z przycisku **[Use this template](https://github.com/new?template_name=organization-template&template_owner=infra-at-scale)** albo zrób [forka](https://github.com/infra-at-scale/organization-template/fork) — i sprawdź, jak ten szkielet zadziała w Twojej organizacji.

Masz pomysł na rozwój?

👉 Przejrzyj [CONTRIBUTING.md](https://github.com/infra-at-scale/organization-template/blob/v1.0.0/docs/CONTRIBUTING.md) i zobacz, jak możesz się włączyć.

Znalazłeś błąd?

👉 Zgłoś issue [tutaj](https://github.com/infra-at-scale/organization-template/issues).
{{< /admonition >}}

{{< buymeacoffee >}}
