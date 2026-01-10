---
title: "Refaktoryzacja HCL w całej organizacji z użyciem OpenRewrite"
subtitle: "Bezpieczne migracje modułów AVM i OpenTofu w praktyce."
code:
  maxShownLines: 60
date: 2026-01-09
description: "Bezpieczne migracje modułów AVM i OpenTofu w praktyce."
draft: false
resources:
- name: "featured-image"
  src: "featured-image.png"
---

W pewnym momencie każdy większy projekt infrastruktury jako kod dochodzi do punktu, w którym zmiany przestają być lokalne. Aktualizacja wersji modułu, zmiana kontraktu wejściowego albo migracja pomiędzy podejściami architektonicznymi wymaga wtedy modyfikacji w wielu miejscach jednocześnie oraz często w kilku repozytoriach.

W teorii są to _"proste"_ zmiany: zmiana wersji, usunięcie parametru, dodanie nowego bloku konfiguracyjnego. W praktyce jednak ręczne refaktoryzowanie takich zmian jest czasochłonne, podatne na błędy i trudne do bezpiecznego review. Skrypty oparte o `grep`, `sed` czy inne operacje tekstowe pomagają tylko do pewnego momentu. Nie rozumieją one struktury konfiguracji, są wrażliwe na formatowanie i, co najważniejsze, **nie są deterministyczne**. Każde kolejne uruchomienie takiego skryptu wymaga ponownej weryfikacji efektu końcowego.

W tym artykule pokazuję, jak podejść do migracji infrastruktury jako kod w sposób deterministyczny, powtarzalny i bezpieczny, wykorzystując refaktoryzację opartą o strukturalną analizę konfiguracji, zachowującą jej semantykę i formatowanie. Na przykładzie rzeczywistych migracji modułów [Azure Verified Modules](https://azure.github.io/Azure-Verified-Modules/) (AVM) pokazuję, jak przygotować zmiany, które trafiają do pull requesta jako czytelny diff zamiast ręcznej pracy rozproszonej po repozytorium.

## Dlaczego OpenRewrite

Kluczową różnicą pomiędzy podejściem opartym o refaktoryzację strukturalną a klasycznymi narzędziami tekstowymi jest to, że operujemy na **semantycznej reprezentacji konfiguracji**, a nie na jej surowej postaci tekstowej. [OpenRewrite](https://docs.openrewrite.org/) wykorzystuje tzw. _lossless semantic trees (LST)_, czyli strukturę, która zachowuje pełną informację o oryginalnym pliku, w tym formatowanie, komentarze i kolejność elementów, jednocześnie umożliwiając bezpieczne modyfikacje semantyczne.

W praktyce oznacza to, że zmiany są aplikowane na rzeczywistych elementach konfiguracji. Na przykład modułach, parametrach czy blokach, a nie na fragmentach tekstu. Dzięki temu refaktoryzacje są **deterministyczne**. To samo wejście zawsze prowadzi do tego samego wyniku, niezależnie od stylu formatowania. Są również **idempotentne**. Wielokrotne uruchomienie tej samej migracji nie powoduje duplikacji ani narastania zmian.

Istotnym efektem tego podejścia jest jakość wyniku. [OpenRewrite](https://docs.openrewrite.org/) zachowuje oryginalną strukturę plików, dzięki czemu wynik migracji trafia do repozytorium jako czytelny, przewidywalny diff, gotowy do standardowego code review. Migracja staje się w ten sposób normalną operacją inżynierską, zakończoną pull requestem, a nie jednorazowym skryptem wymagającym ręcznego sprawdzania.

## Case study

Poniżej przedstawiam konkretną migrację modułu [avm-res-network-virtualnetwork](https://registry.terraform.io/modules/Azure/avm-res-network-virtualnetwork/azurerm/0.10.0) z wersji 0.10.x do 0.11.x. Jest to dobry przykład zmian, które w praktyce można przeprowadzić ręcznie, ale wymagają jednoczesnego uwzględnienia zmiany wersji modułu, usunięcia przestarzałych parametrów oraz wprowadzenia nowego, wymaganego parametru zgodnie z [breaking changes](https://github.com/Azure/terraform-azurerm-avm-res-network-virtualnetwork/releases/tag/v0.11.0) w nowszej wersji.

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

Migracja została opisana jako pojedyncza recipe [OpenRewrite](https://docs.openrewrite.org/), która w sposób jawny definiuje kolejność i zakres zmian: najpierw aktualizację wersji modułu, następnie usunięcie przestarzałych parametrów, a na końcu dodanie nowego wymaganego parametru.

Już na etapie taska `rewriteDryRun` widać, że ta sama migracja została **zastosowana deterministycznie** i spójnie w wielu projektach, bez potrzeby ręcznego wskazywania plików czy katalogów. Każda zmiana jest jednoznacznie przypisana do konkretnej recipe, co ułatwia późniejsze review i audyt:

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

Co istotne, wynikowa zmiana jest lokalna i zapisywana w pliku **rewrite.patch**. Jest także czytelna: nie ma niepowiązanych modyfikacji, a diff dokładnie odpowiada zakresowi zmian opisanych w release notes modułu.

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

Na tym etapie migracja jest gotowa do uruchomienia przez taska `rewriteRun`:

```shell
$ ./gradlew rewriteRun \
  -Drewrite.activeRecipes=io.oczadly.avm.migrations.res.network.virtualnetwork.From010xTo011x \
  -Davm.vnet.parent_id='${data.terraform_remote_state.rg_default_eastus.outputs.resource.id}'
```

A następnie zatwierdzenia w standardowym procesie code review jako zwykły pull request, bez dodatkowych skryptów, wyjątków czy ręcznych poprawek.

## Architektura rozwiązania

Powyższe rozwiązanie składa się z kilku jasno rozdzielonych elementów:

1. Moje recipes w Javie.
2. Recipes w YAML.
3. Gradle.

Każdy z tych elementów pełni inną rolę w całym procesie migracji, a ich rozdzielenie pozwala zachować prostotę, testowalność i możliwość dalszego rozwoju.

### Java recipes

[Oficjalny katalog OpenRewrite](https://docs.openrewrite.org/recipes) nie zawiera recipes do zmiany wersji modułu, usuwania ani dodawania parametrów wejściowych w modułach [OpenTofu](https://opentofu.org/) / [Terraform](https://developer.hashicorp.com/terraform). Z tego powodu powstał zestaw własnych recipes, opublikowany w repozytorium [paweloczadly/openrewrite-recipes](https://github.com/paweloczadly/openrewrite-recipes).

Oprócz implementacji niezbędnych funkcji recipes zawierają solidny zestaw testów jednostkowych, które wprost weryfikują ich zachowanie i stanowią pierwszą linię zabezpieczenia przed niepożądanymi zmianami w strukturze HCL. Całość, w procesie CD, publikowana jest do [Maven Central](https://central.sonatype.com/artifact/io.oczadly/openrewrite-recipes/overview).

Ten element można traktować jako **silnik refaktoryzacji**, niezależny od konkretnych migracji czy projektów.

### YAML recipes

Repozytorium [infra-at-scale/avm-openrewrite-migrations](https://github.com/infra-at-scale/avm-openrewrite-recipes) zawiera recipes w YAML, które wywołują opisane wcześniej Java recipes. Na tym poziomie definiowane są już konkretne migracje dla modułów AVM w sposób jawny, deklaratywny i możliwy do wersjonowania.

Każda YAML recipe opisuje __co__ ma zostać zmienione: docelową wersję modułu, usuwane parametry oraz nowe wymagane parametry, bez ingerencji w mechanikę samego refaktoringu. Dzięki temu logika migracji jest oddzielona od jej wykonania, a same recipes mogą być łatwo przeglądane, testowane i zatwierdzane w standardowym procesie code review.

W praktyce YAML recipes pełnią rolę warstwy decyzyjnej (_"policy layer"_). Pozwalają one opisać migrację jednego lub wielu projektów w sposób powtarzalny, deterministyczny i niezależny od konkretnego repozytorium czy struktury katalogów.

### Gradle

Aby uczynić te migracje powtarzalnymi, wykorzystuję [Gradle](https://gradle.org/) jako silnik wykonawczy. Odpowiada on za uruchamianie recipes [OpenRewrite](https://docs.openrewrite.org/), zapewnia spójność wykonania i umożliwia łatwe odtworzenie tego samego procesu lokalnie oraz w CI.

W organizacjach, które już korzystają z [Develocity](https://gradle.com/develocity/), ten sam workflow może publikować [Build Scan'y](https://docs.gradle.org/9.0.0/userguide/build_scans.html), co daje dodatkowe observability przebiegu migracji oraz możliwość porównywania wyników pomiędzy projektami, bez zmiany samego modelu wykonania.

## Gwarancje bezpieczeństwa

Migracje infrastruktury jako kod są ryzykowne nie dlatego, że są trudne technicznie, ale dlatego, że często są **niedeterministyczne**, trudne do zweryfikowania i wykonywane ad-hoc. W przedstawionym podejściu bezpieczeństwo migracji nie wynika z ostrożności wykonawcy, lecz z właściwości samego procesu.

Poniżej opisuję, jakie gwarancje zapewnia zaproponowana architektura.

### Deterministyczność zmian

Każda migracja jest opisana w postaci jawnej recipe YAML [OpenRewrite](https://docs.openrewrite.org/). Oznacza to, że dla danego stanu wejściowego kod wyniku refaktoryzacji jest zawsze taki sam. Niezależnie od tego, kto i gdzie uruchamia ten proces. Nie ma tu miejsca na wyrażenia regularne ani kolejność dopasowań zależną od środowiska.

Deterministyczność jest kluczowa zwłaszcza w organizacjach, gdzie ta sama migracja musi zostać zastosowana w wielu repozytoriach lub środowiskach.

### Idempotentność

Recipes [OpenRewrite](https://docs.openrewrite.org/) są idempotentne. Ich wielokrotne uruchomienie nie powoduje kumulowania zmian. Jeśli dana migracja została już zastosowana, kolejne wykonanie procesu nie wprowadzi dodatkowych modyfikacji.

Dzięki temu migracje mogą być:

- [x] Bezpiecznie uruchamiane wielokrotnie.
- [x] Integrowane z CI.
- [x] Stosowane etapami, bez ryzyka zmian stanu infrastruktury.

### Jawność i audyt

Zarówno Java recipes, jak i YAML recipes są przechowywane w repozytoriach Git. Cała logika migracji jest widoczna, wersjonowana i podlega standardowemu code review.

Nie ma tu:

- Ukrytych skryptów.
- Dynamicznie generowanych poleceń.
- Zmian wykonywanych "poza repozytorium".

Dodatkowo, Java recipes są publikowane do [Maven Central](https://central.sonatype.com/artifact/io.oczadly/openrewrite-recipes/overview) w automatycznym procesie CI/CD. Oznacza to, że artefakty są wersjonowane, podpisywane i możliwe do jednoznacznego zidentyfikowania w łańcuchu dostaw oprogramowania. Sam fakt publikacji nie jest gwarancją jakości, ale stanowi kolejny, audytowalny element procesu. Zarówno pod kątem pochodzenia kodu, jak i jego niezmienności po wydaniu.

### Kontrola przed wdrożeniem

Możliwość uruchomienia migracji w trybie `rewriteDryRun` pozwala, tak jak w `tofu plan` / `terraform plan`, zobaczyć pełny zakres planowanych zmian. W tym przypadku bez modyfikowania kodu.

Daje to przestrzeń na:

- Ocenę wpływu migracji.
- Wychwycenie nieoczekiwanych efektów.
- Podjęcie świadomej decyzji o jej wdrożeniu.

### Podsumowanie

Bezpieczeństwo przedstawionego podejścia nie opiera się na ręcznej kontroli ani ostrożności, lecz na **właściwościach systemu**: deterministyczności, idempotentności oraz jawności zmian. Dzięki temu migracje infrastruktury jako kod przestają być jednorazowym, ryzykownym wydarzeniem, a stają się powtarzalnym i kontrolowanym procesem.

## Dlaczego to skaluje się w organizacji

Opisane podejście skaluje się w organizacji nie dlatego, że wykorzystuje konkretne narzędzia, ale dlatego, że **adresuje problem na właściwym poziomie abstrakcji**. Migracje nie są tu traktowane jako jednorazowe zadania wykonywane ręcznie w poszczególnych repozytoriach, lecz jako **jawnie opisany proces**, który można wielokrotnie zastosować w różnych kontekstach.

Kluczowe jest rozdzielenie odpowiedzialności:

1. Java recipes definiują **JAK** wykonywać bezpieczny refaktoring HCL.
2. YAML recipes opisują **CO** dokładnie ma zostać zmienione w danej migracji.
3. [Gradle](https://gradle.org/) zapewnia powtarzalny sposób uruchamiania całego procesu lokalnie oraz w CI.

Dzięki temu ta sama migracja może być zastosowana w wielu repozytoriach, uruchamiana przez różne zespoły, integrowana z istniejącymi procesami code review oraz CI/CD.

Co istotne, to podejście nie wymaga centralnego systemu, ani dedykowanej platformy. Wystarczają repozytoria Git oraz standardowy workflow pull requestów. To wszystko sprawia, że rozwiązanie dobrze wpisuje się w realia organizacji o różnym poziomie dojrzałości.

## Kiedy to podejście nie ma sensu

Opisane podejście nie będzie dobrym rozwiązaniem w sytuacji, gdy projekt infrastruktury jako kod jest niewielki, obejmuje pojedynczy moduł i nie planuje się jego dalszego rozwoju ani aktualizacji. W tym przypadku koszt wprowadzenia dodatkowego procesu może przewyższyć potencjalne korzyści.

Podobnie, w sytuacjach wymagających jednorazowej, standardowej zmiany (np. tylko podbicia wersji w jednym miejscu), modyfikacja przez [Renovate](https://docs.renovatebot.com/) / inną automatyzację lub nawet ręczna może być prostszym i bardziej adekwatnym rozwiązaniem.

Warto też podkreślić, że podejście to zakłada pewien poziom dojrzałości organizacyjnej: pracę z pull requestami, code review oraz gotowość do traktowania migracji jako elementu długofalowego utrzymania, a nie incydentalnej poprawki.

## Podsumowanie

Migracje infrastruktury jako kod są nieuniknione. Zmieniają się wersje modułów, wymagania dostawców chmurowych oraz dobre praktyki. Problemem nie jest sama zmiana, lecz **sposób jej przeprowadzania**.

W artykule pokazałem, jak podejść do refaktoryzacji [OpenTofu](https://opentofu.org/) / [Terraform](https://developer.hashicorp.com/terraform) w sposób deterministyczny, powtarzalny i bezpieczny, wykorzystując [OpenRewrite](https://docs.openrewrite.org/) jako silnik refaktoryzacji, a [Gradle](https://gradle.org/) jako mechanizm uruchomieniowy. Zamiast skryptów opartych na `grep` i `sed`, które są trudne do utrzymania i weryfikacji, zaproponowane podejście opiera się na jawnych recipes, minimalnych diffach i pull requestach jako jedynym wyniku procesu.

Dzięki temu migracje przestają być ryzykownym, jednorazowym wydarzeniem, a stają się **kontrolowanym procesem inżynierskim**, który można rozwijać, audytować i bezpiecznie stosować w całej organizacji.

{{< admonition example "Co dalej?" >}}

Jeśli pracujesz z AVM lub innymi dużymi bazami [OpenTofu](https://opentofu.org/) / [Terraform](https://developer.hashicorp.com/terraform) i zastanawiasz się, jak bezpiecznie podejść do migracji, to podejście możesz przetestować w praktyce.

👉 Zajrzyj do repozytorium [infra-at-scale/avm-openrewrite-migrations](https://github.com/infra-at-scale/avm-openrewrite-recipes) i uruchom migracje na swoich projektach.

Chcesz dodać nowe funkcjonalności albo naprawić błąd w recipes?

👉 Zrób fork [paweloczadly/openrewrite-recipes](https://github.com/paweloczadly/openrewrite-recipes) i wprowadź potrzebne zmiany.

A jeśli spotykasz się ze skomplikowanymi scenariuszami migracji albo chcesz przedyskutować proponowane przeze mnie podejście w Twojej organizacji:

👉 skontaktuj się ze mną pod [contact@oczadly.io](mailto:contact@oczadly.io).

{{< /admonition >}}

{{< buymeacoffee >}}
