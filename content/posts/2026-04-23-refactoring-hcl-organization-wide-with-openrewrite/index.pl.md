---
title: "Refaktoryzacja HCL w całej organizacji z użyciem OpenRewrite"
subtitle: "Bezpieczne migracje modułów AVM i OpenTofu w praktyce."
code:
  maxShownLines: 70
date: 2026-04-23
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

{{< admonition tip "To podejście nie kończy się na HCL" >}}

Warto też zauważyć, że to podejście nie jest ograniczone do HCL ani [OpenTofu](https://opentofu.org/) / [Terraform](https://developer.hashicorp.com/terraform). [OpenRewrite](https://docs.openrewrite.org/) oferuje analogiczne, semantycznie świadome refaktoryzacje dla innych formatów konfiguracyjnych, w tym YAML-i wykorzystywanych w ekosystemie [Kubernetes](https://kubernetes.io/) ([Helm](https://helm.sh/), [Flux](https://fluxcd.io/), [Argo CD](https://argoproj.github.io/cd/)).

Oznacza to, że ten sam model pracy, czyli jawne recipes, deterministyczne wykonanie i pull request jako wynik, może być zastosowany również do migracji manifestów Kubernetesowych, zmian API czy refaktoryzacji konfiguracji GitOps. To temat na osobne case study.

{{< /admonition >}}

## Case study

### Prosty przykład

Zanim przejdziesz do bardziej złożonego scenariusza, przyjrzyj się prostemu przykładowi. Moduł [avm-res-network-virtualnetwork](https://registry.terraform.io/modules/Azure/avm-res-network-virtualnetwork/azurerm/0.10.0) przeszedł w wersji 0.11.0 zmianę kontraktu: usunięcie `resource_group_name` i `subscription_id`, dodanie wymaganego `parent_id`. To typowe zmiany inżynierskie: proste koncepcyjnie, ale ryzykowne do zastosowania ręcznie w wielu miejscach.

Migracja jest opisana jako [OpenRewrite](https://docs.openrewrite.org/) recipe:

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

To wystarczy. Migracja jest niezmienna, powtarzalna i gotowa do zastosowania w całej organizacji.

### Złożony scenariusz

Teraz przejdźmy do rzeczywistości. Moduł [avm-res-network-privatednszone](https://github.com/Azure/terraform-azurerm-avm-res-network-privatednszone/releases/tag/v0.4.0) w wersji 0.4.0 przeszedł gruntowną refaktoryzację. Zmienił się nie tylko kontrakt, ale architektura samego modułu: przejście z zasobów Azurem na `azapi`, używanie bloków `removed` i `import` do migracji stanu. To już nie jest prosta zmiana, to jest **złożona, wieloetapowa refaktoryzacja**.

#### Co się musiało zmienić

W starej wersji (0.3.x) moduł zarządzał zasobami bezpośrednio przez zasoby Azurerm: `azurerm_private_dns_zone`, `azurerm_private_dns_zone_virtual_network_link`, rekordy DNS (`azurerm_private_dns_a_record`, itp.) oraz przypisania ról.

W nowej wersji (0.4.0) wszystko przesunęło się na `azapi_resource`. Oznacza to, że zasoby, które istnieją w stanie [OpenTofu](https://opentofu.org/) / [Terraform](https://developer.hashicorp.com/terraform) z wersji 0.3.x, muszą zostać **przeniesione** do nowej reprezentacji: nie usunięte i ponownie utworzone. Dla infrastruktury produkcyjnej to jest krytyczne: zamiast destrukcji i rekonstrukcji chcemy dać znać [OpenTofu](https://opentofu.org/) / [Terraform](https://developer.hashicorp.com/terraform): _"ten zasób istnieje tam gdzie jest, ale teraz będziemy nim zarządzać inaczej"_.

#### Struktura migracji

Recipe YAML dla tej migracji robi pięć rzeczy:

**1. Przygotowanie środowiska**: dodanie wymaganych providerów (`azapi`, `modtm`).

```yaml
- io.oczadly.openrewrite.hcl.AddProvider:
    source: "Azure/avm-res-network-privatednszone/azurerm"
    version: "~> 0.3.5"
    providerName: "azapi"
    providerSource: "azure/azapi"
    providerVersion: "~> 2.5.0"
```

**2. Podbicie wersji**: z `~> 0.3.5` do `~> 0.4.0`.

```yaml
- io.oczadly.openrewrite.hcl.ChangeModuleVersion:
    source: "Azure/avm-res-network-privatednszone/azurerm"
    version: "~> 0.3.5"
    newVersion: "~> 0.4.0"
```

**3. Konwersja locals**: z typu `string` na `list`.

```yaml
- io.oczadly.openrewrite.hcl.ConvertLocalValueInPath:
    source: "Azure/avm-res-network-privatednszone/azurerm"
    version: "~> 0.4.0"
    localName: txt_records
    attributePath: "*.records.*.value"
    transformation: stringToList
```

**4. Modyfikacja parametrów wejściowych**: usunięcie `resource_group_name` i dodanie `parent_id`.

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

**5. Migracja zasobów**: trzy warianty dla każdego zasobu.

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

Proces jest powtórzony dla każdego zasobu: stref DNS, linków sieciowych, przypisań ról, rekordów DNS (A, AAAA, CNAME, MX, PTR, SRV, TXT).

#### Dlaczego to wiele linii?

Recipe dla privatednszone zawiera ~180 linii, głównie powtórzenia tego samego wzorca aplikowanego do różnych zasobów. Czy to słaba konstrukcja? Nie. To jest _jawna_, _deklaratywna_ lista zmian. Każda linia odpowiada jednej operacji, którą chcemy przeprowadzić. Na etapie code review dokładnie widać: _"Ah, migrujemy osiem typów rekordów DNS, każdy zostanie usunięty ze stanu, a następnie importowany"_.

W praktyce, gdy uruchamiasz `rewriteDryRun`:

```shell
$ ./gradlew rewriteDryRun \
  -Drewrite.activeRecipes=io.oczadly.avm.migrations.res.network.privatednszone.From03xTo04x \
  -Davm.pdns.subscription_id="..." \
  -Davm.pdns.private_dns_zone_name="..."
```

Widzisz efekt: nie sześć kopii tego samego bloku repetycyjnie, lecz konkretne wpisy dla każdego zasobu, które znajdują się w Twoim kodzie.

#### Wynik migracji

Po zastosowaniu recipe YAML wynikowy diff pokazuje:

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
/* Pozostałe bloki removed pominięte dla przejrzystości */
+
+import {
+  to = module.private_dns_zones.azapi_resource.private_dns_zone
+  id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/avmrg/providers/Microsoft.Network/privateDnsZones/testlab.io?api-version=2024-06-01"
+}
+
/* Pozostałe bloki import pominięte dla przejrzystości */

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
/* Pozostałe zmiany w locals pominięte dla przejrzystości */
```
Jak widać powyżej, zmiany dotyczą trzech plików:

1. **main.tf**: wersja modułu zmienia się z `~> 0.3.5` na `~> 0.4.0`, parametr `resource_group_name` zostaje usunięty, pojawia się `parent_id`, oraz bloki `removed` i `import` dla każdego zasobu. Z przyczyn przejrzystości pokazano tylko przykłady dla stref DNS. Pattern ten powtarza się identycznie dla `aaaa_record`, `cname_record`, `mx_record`, `ptr_record`, `srv_record` i `txt_record`.

2. **locals.tf**: wartości tekstowe dla rekordów DNS (np. `txt_records`) zostają automatycznie przekonwertowane na listy stringu: `"banana"` zmienia się na `["banana"]`. To jest niezbędne, ponieważ nowa wersja modułu oczekuje tego formatu.

3. **terraform.tf**: dodaje się provider `azapi` w wymaganej konfiguracji. To jest kluczowe, ponieważ nowa wersja modułu używa zasobów `azapi_resource` zamiast zasobów Azurerm.

[OpenTofu](https://opentofu.org/) / [Terraform](https://developer.hashicorp.com/terraform) w `plan` pokaże: _"Resource will be imported"_. Po `apply` zasób zostanie ponownie zarejestrowany bez zmiany rzeczywistego stanu na Azure.

#### Powtarzalność

To, co robisz dla jednej Private DNS Zone, możesz odtworzyć dla dziesięciu. Ta sama recipe i parametry zawsze dają ten sam efekt. Bez skryptów, bez ręcznych poprawek, bez ryzyka, że coś przeoczyłeś.

---

Na tym etapie migracja jest gotowa do uruchomienia przez taska `rewriteRun` i zatwierdzenia w standardowym procesie code review jako zwykły pull request, bez dodatkowych skryptów, wyjątków czy ręcznych poprawek.

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

Co istotne, zaprezentowany model refaktoryzacji nie jest związany z jednym formatem ani jednym narzędziem. Jawne recipes, deterministyczne wykonanie i pull request jako wynik tworzą uniwersalne podejście do bezpiecznej ewolucji konfiguracji infrastrukturalnych.

{{< admonition example "Co dalej?" >}}

Jeśli pracujesz z AVM i zastanawiasz się, jak bezpiecznie podejść do migracji, to podejście możesz przetestować w praktyce.

👉 Zajrzyj do repozytorium [infra-at-scale/avm-openrewrite-migrations](https://github.com/infra-at-scale/avm-openrewrite-migrations) i uruchom migracje na swoich projektach.

Chcesz dodać nowe funkcjonalności albo naprawić błąd w recipes?

👉 Zrób fork [paweloczadly/openrewrite-recipes](https://github.com/paweloczadly/openrewrite-recipes) i wprowadź potrzebne zmiany.

A jeśli spotykasz się ze skomplikowanymi scenariuszami migracji w ekosystemie [OpenTofu](https://opentofu.org/) / [Terraform](https://developer.hashicorp.com/terraform) lub w konfiguracjach [Kubernetes](https://kubernetes.io/) ([Helm](https://helm.sh/), [Flux](https://fluxcd.io/), [Argo CD](https://argoproj.github.io/cd/)), albo chcesz przedyskutować zastosowanie tego podejścia w Twojej organizacji:

👉 skontaktuj się ze mną pod [contact@oczadly.io](mailto:contact@oczadly.io).

{{< /admonition >}}

{{< buymeacoffee >}}
