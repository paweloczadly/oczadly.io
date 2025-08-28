---
title: "gradle init dla Spring Boot"
subtitle: "Produkcyjny plugin Gradle inspirowany praktykami z DPE University."
date: 2025-08-28
description: "Produkcyjny plugin Gradle inspirowany praktykami z DPE University."
draft: false
lightgallery: true
resources:
- name: "featured-image"
  src: "featured-image.png"
- name: "install.sh"
  src: install.sh
---

## Dlaczego kolejny plugin Gradle

Ostatnio chciałem poszerzyć swoją wiedzę o [Build Scanach](https://docs.gradle.org/9.0.0/userguide/build_scans.html), [Develocity](https://gradle.com/develocity/) i ich praktycznym zastosowaniu, dlatego zacząłem przerabiać kursy na naszej platformie [DPE University](https://dpeuniversity.gradle.com/app/catalog). Na co dzień mam styczność z [Develocity](https://gradle.com/develocity/) od strony operacyjnej i produkcyjnej – utrzymuję między innymi [instancje open source](https://github.com/gradle/develocity-oss-projects), więc zależało mi na lepszym zrozumieniu produktu, a zwłaszcza użycia od strony użytkowników, w mojej codziennej pracy inżyniera.

Aby usystematyzować zdobytą wiedzę, postanowiłem zbudować projekt zgodny z best practices omawianymi na kursach. Równolegle pracowałem nad mikroserwisem w [Spring Boot](https://spring.io/projects/spring-boot), generowanym ze [Spring Initializr](https://start.spring.io/), i zauważyłem brak [pluginu Gradle](https://docs.gradle.org/9.0.0/userguide/plugins.html), który automatyzowałby ten proces w sposób przyjazny build cache i CI/CD. W efekcie każdy nowy projekt wymagał ręcznej konfiguracji. Chciałem to uprościć i zbliżyć doświadczenie do znanego `gradle init` – ale w wersji dla [Spring Boot](https://spring.io/projects/spring-boot).

Tak powstał [gradle-springinitializr-plugin](https://plugins.gradle.org/plugin/io.oczadly.springinitializr) – narzędzie gotowe do użycia na produkcji, które ułatwia tworzenie projektów [Spring Boot](https://spring.io/projects/spring-boot) z poziomu [Gradle](https://gradle.org/). Ten wpis jest o tym, jak powstał, jak działa i jak możesz go wykorzystać, aby przyspieszyć start nowych projektów w swoim zespole.

{{< admonition example "Szybki start" >}}
Plugin jest open source i dostępny w [Gradle - Plugins](https://plugins.gradle.org/plugin/io.oczadly.springinitializr). Możesz od razu go zainstalować i używać.

Stwórz plik `build.gradle` oraz dodaj poniższe:

```groovy
plugins {
    id 'io.oczadly.springinitializr' version '1.0.0'
}
```

Następnie stwórz plik `settings.gradle` i dodaj konfigurację:

```groovy
rootProject.name = 'examples-simple-groovy'
```

Lub dodaj konfigurację do `build.gradle` w swoim istniejącym projekcie.

Dzięki temu będziesz mógł generować kolejne projekty [Spring Boot](https://spring.io/projects/spring-boot) z [Gradle](https://gradle.org/) od razu podczas czytania wpisu, przyspieszając swój onboarding i codzienną pracę.

👉 [Gradle - Plugins](https://plugins.gradle.org/plugin/io.oczadly.springinitializr)

👉 [GitHub](https://github.com/paweloczadly/gradle-springinitializr-plugin)
{{< /admonition >}}

Ten plugin traktuję jako wzorzec: jak budować produkcyjny plugin w [Groovy](https://groovy-lang.org/) zgodny z [Gradle best practices](https://docs.gradle.org/9.0.0/userguide/best_practices_general.html). Jeśli sam tworzysz pluginy, możesz go użyć jako punkt odniesienia.

---

## Dla kogo

**Dla Platform Engineerów**

[gradle-springinitializr-plugin](https://plugins.gradle.org/plugin/io.oczadly.springinitializr) może stać się elementem Waszej platformy, który przyspieszy tworzenie mikroserwisów w organizacji. Dzięki niemu możecie:

✅ Szybko generować mikroserwisy [Spring Boot](https://spring.io/projects/spring-boot) ([Groovy](https://groovy-lang.org/)/[Java](https://www.java.com/)/[Kotlin](https://kotlinlang.org/), [Gradle](https://gradle.org/)/[Maven](https://maven.apache.org/)) z CLI, pipeline’ów lub automatycznych procesów [GitOps](https://www.gitops.tech/).

✅ Generować projekty zawsze z aktualną wersją [Spring Boot](https://spring.io/projects/spring-boot), [Javy](https://www.java.com/) i zależności, eliminując ręczne utrzymywanie szablonów.

✅ Standaryzować strukturę projektów, metadane (groupId, artifactId, packageName, description) i proces tworzenia mikroserwisów.

Jeśli budujecie platformę inżynierską dla zespołów developerskich w ekosystemie JVM, ten plugin może stać się Waszym lekko konfigurowalnym, automatyzowalnym elementem pipeline do bardzo prostego tworzenia projektów [Spring Boot](https://spring.io/projects/spring-boot).

**Dla Software Engineerów**

[gradle-springinitializr-plugin](https://plugins.gradle.org/plugin/io.oczadly.springinitializr) może stać się Waszym pierwszym wyborem do szybkiego startu projektów [Spring Boot](https://spring.io/projects/spring-boot) bez opuszczania ekosystemu [Gradle](https://gradle.org/).
Zamiast klikania w webowe UI [Spring Initializr](https://start.spring.io/) czy pisania curli, generujecie w pełni konfigurowalny projekt jedną komendą [Gradle](https://gradle.org/).
To oszczędność czasu, spójność konfiguracji i od razu wpięcie w Wasz workflow build cache, CI/CD oraz konwencje zespołowe.

**Dla osób ciekawych i świadomych**

[gradle-springinitializr-plugin](https://plugins.gradle.org/plugin/io.oczadly.springinitializr) pozwoli Wam w jedną minutę zobaczyć, jak wygląda proces generowania projektu [Spring Boot](https://spring.io/projects/spring-boot) z poziomu [Gradle](https://gradle.org/), bez klikania po https://start.spring.io czy pisania curli. Zamiast ręcznego ściągania ZIP-ów, od razu startujecie projekt lokalnie i możecie eksplorować [Spring Boot](https://spring.io/projects/spring-boot) w sposób powtarzalny, czysty i przyjazny.

---

## Jak działa

Po zainstalowaniu [gradle-springinitializr-plugin](https://plugins.gradle.org/plugin/io.oczadly.springinitializr) możesz generować projekty [Spring Boot](https://spring.io/projects/spring-boot) bezpośrednio z [Gradle](https://gradle.org/), bez opuszczania terminala.

Plugin udostępnia pojedynczy task `initSpringBootProject`, który pobiera projekt z [Spring Initializr](https://start.spring.io/) i następnie rozpakowuje go. Zamiast klikać w interfejs webowy, wystarczy uruchomić:

```shell
gradle initSpringBootProject
```

Otrzymasz:

```text
> Task :initSpringBootProject
Downloading Spring Boot starter project...
Project downloaded to: /opt/my-projects/build/generated-project/starter.zip
Project extracted to: /opt/my-projects/build/generated-project/demo

BUILD SUCCESSFUL in 1s
```

Domyślnie projekt zostanie pobrany i rozpakowany do `build/generated-project/demo`, gotowy do otwarcia i uruchomienia.

Plugin pozwala także ustawić dowolny parametr dostępny w [Spring Initializr](https://start.spring.io/):

```shell
gradle initSpringBootProject \
    -PprojectType="gradle-project-kotlin" \
    -Planguage="kotlin" \
    -PgroupId="com.mycompany" \
    -PartifactId="my-spring-app" \
    -PprojectName="My Spring App" \
    -PprojectDescription="My Spring Boot application generated via gradle-springinitializr-plugin" \
    -PpackageName="com.mycompany.myspringapp" \
    -Ppackaging="war" \
    -PjavaVersion="21" \
    -Pdependencies="web,actuator"
    -PoutputDir="/opt/my-projects/my-spring-boot-app"
```

Dzięki temu możesz generować czyste, spójne projekty, gotowe do pracy w Twoim workflow CI/CD i zgodne z zespołowymi konwencjami – bez manualnych kroków.

Plugin wspiera także eksperymentalny tryb interaktywny wzorowany na komendzie `gradle init`:

![gradle init dla Spring Boot](https://raw.githubusercontent.com/paweloczadly/gradle-springinitializr-plugin/refs/tags/v1.0.0/docs/images/demo.gif "gradle init dla Spring Boot")

Dzięki temu możesz wprowadzić wszystkie parametry projektu bez konieczności zapamiętywania flag wiersza poleceń - plugin przeprowadza go krok po kroku przez proces wyboru wersji [Spring Boot](https://spring.io/projects/spring-boot), języka, typu projektu i zależności. To szczególnie przydatne dla nowych członków zespołu lub w sytuacjach, gdy chcemy szybko przygotować projekt w standardzie naszej organizacji.

{{< admonition warning "UWAGA" >}}
Tryb interaktywny jest wciąż eksperymentalny — świetny do nauki i szybkiego startu. W pipeline’ach CI/CD rekomenduję jawne flagi -P.
{{< /admonition >}}

Aby skorzystać z trybu interaktywnego, należy podążać za instrukcjami z [FAQ](https://github.com/paweloczadly/gradle-springinitializr-plugin/blob/v1.0.0/FAQ.md#is-interactive-mode-supported).

---

## Jak został zbudowany

Jak wspomniałem wcześniej, poza wykorzystaniem wiedzy z kursów [DPE University](https://dpeuniversity.gradle.com/app/catalog), chciałem, aby ten plugin był **referencyjną implementacją** pod budowę kolejnych pluginów. Moim celem było stworzenie czegoś solidnego, niemal bezobsługowego oraz tak bardzo ponadczasowego, jak to możliwe.

### `plugin.properties`

Sercem pluginu jest plik `plugin.properties`, który zawiera domyślne wartości parametrów. To rozwiązanie wspiera zasadę *separacji kodu oraz konfiguracji* - zmiany wartości nie wymagają modyfikacji ani rekompilacji kodu, tylko podmiany pliku.

Plik properties jest ładowany raz przy starcie pluginu i wartości dostępne są poprzez statyczne stałe:

```groovy
PluginConfig.getOrThrow(PluginConstants.PLUGIN_ID)
```

Takie podejście upraszcza zarówno konfigurację produkcyjną, jak i testową – dając pełną kontrolę nad środowiskiem bez zmian w logice pluginu.

{{< admonition success "Wnioski z testów funkcjonalnych" >}}
Aby `plugin.properties` był widoczny w testach funkcjonalnych jako zasób, należy dodać w `build.gradle`:

```groovy
sourceSets {
    functionalTest {
        resources.srcDir file('src/main/resources')
    }
}
```

Dzięki temu testy funkcjonalne korzystają z dokładnie tej samej konfiguracji co produkcyjny plugin.
{{< /admonition >}}

### `convention`: czysta konfiguracja pluginu

Opcje takie jak `initializrUrl`, `metadataEndpoint` i `extract` są zaprojektowane jako **konfiguracja globalna pluginu** – dotyczą źródła danych (czyli *skąd* pobierać projekt), a nie samego projektu (*co* ma zawierać). Dzięki temu plugin zachowuje separację między konfiguracją infrastrukturalną a właściwą logiką generowania.

Domyślne wartości są ustawiane przez mechanizm [`convention(...)`](https://docs.gradle.org/9.0.0/userguide/lazy_configuration.html#applying_conventions) w [Gradle](https://gradle.org) - co oznacza:

* użytkownik *nie musi nic ustawiać*, aby użyć pluginu w trybie domyślnym,
* ale *może nadpisać* dowolną wartość w `build.gradle`, jeśli chce użyć np. własnej wersji [Spring Initializr](https://start.spring.io/) lub zablokować rozpakowanie ZIP-a, jak poniżej:

```groovy
plugins {
    id 'io.oczadly.springinitializr' version '1.0.0'
}

tasks.named('initSpringBootProject') {
    initializrUrl = 'https://your-initializr.example.com'
    metadataEndpoint = '/yours'
    extract = 'false'
}
```

To podejście zapewnia:

* **czystość buildów** - nie trzeba mieszać konfiguracji z parametrami wywołania.
* **przewidywalność** - plugin zawsze działa na jawnie zdefiniowanych danych wejściowych.
* **elastyczność** - użytkownik może użyć własnego endpointu, np. w CI albo mirrorze.

Zobacz oficjalną [dokumentację Gradle dotyczącą `convention(...)`](https://docs.gradle.org/9.0.0/userguide/lazy_configuration.html#applying_conventions), aby dowiedzieć się, jak ustawiać przejrzyste, nadpisywalne wartości domyślne we własnych pluginach i taskach.

### Wyciąganie dostępnych opcji z Metadata API

Plugin pobiera wspierane wersje między innymi [Spring Boot](https://spring.io/projects/spring-boot), typów projektu oraz języków, w których można programować aplikacje po pobraniu ze [Spring Initializr](https://start.spring.io/). Jest to dostępne przy użyciu [Metadata endpoint](https://docs.spring.io/initializr/docs/current/reference/html/#metadata-format). Dzięki temu nie ma potrzeby ciągłego aktualizowania pluginu o wspierane parametry.

Podczas dodawania wspieranych typów projektów oraz języków natknąłem się na ciekawy problem z użyciem [configuration cache](https://docs.gradle.org/9.0.0/userguide/configuration_cache.html) w [Gradle](https://gradle.org). O którym poniżej.

{{< admonition success "Wnioski z używania --configuration-cache" >}}
Na początku napotkałem kilka problemów podczas testowania pluginu z flagą `--configuration-cache`. Początkowo sądziłem, że problem wynika z odczytu `plugin.properties`, ale prawdziwą przyczyną było korzystanie z API `project.*` w klasie rozszerzającej `DefaultTask`:

```groovy
package io.oczadly.tasks

abstract class InitSpringBootProjectTask extends DefaultTask {

  @Internal
  final ListProperty<String> supportedProjectTypes = project.objects.listProperty String

  @Internal
  final ListProperty<String> supportedLanguages = project.objects.listProperty String

  @TaskAction
  void download() {
    /* Pozostały kod pominięty dla przejrzystości */
  }
}
```

To łamie mechanizm [configuration cache](https://docs.gradle.org/9.0.0/userguide/configuration_cache.html), ponieważ [Gradle](https://gradle.org) wymaga, aby wszystkie dane wejściowe były jawnie zadeklarowane przy użyciu `Property<T>`, `Provider<T>` lub `DirectoryProperty`. Następnie w fazie wykonania nie można odwoływać się do zmiennego stanu projektu.

Rozwiązałem to przez:

- [x] Przeniesienie całej logiki pobierania wspieranych typów projektu i języków do metody `download()`.

- [x] Upewnienie się, że `@TaskAction` operuje wyłącznie na właściwościach deklarowanych jako `Property<T>` lub `Provider<T>`, czyli ocenianych dopiero w czasie wykonania.

Ta zmiana nie tylko umożliwiła zgodność pluginu z configuration cache, ale też doprowadziła do czystszej, bardziej idiomatycznej implementacji zgodnej z praktykami [Gradle](https://gradle.org).

Zobacz oficjalną [dokumentację Gradle dotyczącą configuration cache](https://docs.gradle.org/9.0.0/userguide/configuration_cache.html), aby poznać wszystkie szczegóły i ograniczenia.
{{< /admonition >}}


### Parametry `-P` i mechanizm walidacji

Plugin akceptuje wszystkie parametry dostępne na stronie https://start.spring.io - te same, które możesz ustawić w webowym UI [Spring Initializr](https://start.spring.io).

Po ustawieniu przez użytkowników parametrów albo przypisania domyślnych wartości, w tasku `initSpringBootProject` jest robiona walidacja. Task na początku pobiera listę wspieranych wersji [Spring Boot](https://spring.io/projects/spring-boot), typów projektu oraz języków z endpointu [Metadata](https://docs.spring.io/initializr/docs/current/reference/html/#project-metadata). Jeśli użytkownik poda błędną wartość parametru, która nie jest wspierana task zakończy się błędem. Na przykład:

```shell
gradle initSpringBootProject -Planguage=clojure
```

Dostanie komunikat:

```text
> Task :initSpringBootProject FAILED

FAILURE: Build failed with an exception.

* What went wrong:
Execution failed for task ':initSpringBootProject'.
> Unsupported language: 'clojure'. Supported: java, kotlin, groovy.

* Try:
> Run with --stacktrace option to get the stack trace.
> Run with --info or --debug option to get more log output.
> Run with --scan to get full insights.
> Get more help at https://help.gradle.org.

BUILD FAILED in 5s
```

### Incremental build i build cache

Na podstawie ścieżki [Gradle Build Caching](https://dpeuniversity.gradle.com/app/learning_paths/b82f8dd7-d61e-450f-820e-3e719ef70bee) na [DPE University](https://dpeuniversity.gradle.com/app/catalog) oraz wiedzy tam nabytej w pluginie zostało dodane wsparcie do [incremental build](https://docs.gradle.org/9.0.0/userguide/incremental_build.html) oraz [Build Cache](https://docs.gradle.org/9.0.0/userguide/build_cache.html). Dzięki temu kolejne uruchomienia są natychmiastowe, a rezultaty mogą być ponownie użyte.

Task `initSpringBootProject` deklaruje zarówno dane wejściowe (`@Input`), jak i dane wyjściowe (`@OutputDirectory` - w tym przypadku `outputDir`, powiązany z `DirectoryProperty`). To zgodne z definicją poprawnie skonfigurowanego taska w [Gradle](https://gradle.org), opisaną [tutaj](https://docs.gradle.org/9.0.0/userguide/incremental_build.html#sec:task_inputs_outputs).

Dzięki temu [Gradle](https://gradle.org) ma pełną kontrolę nad śledzeniem stanu wejść i wyjść, co umożliwia:

* Pomijanie taska (`UP-TO-DATE`), jeśli dane wyjściowe się nie zmieniły - incremental build.
* Przywrócenie wyników (`FROM-CACHE`), jeśli dane wyjściowe są w lokalnym cache - build cache.

Poniżej znajduje się przykład, jak task zachowuje się w obu przypadkach.

#### Incremental build

Przy pierwszym uruchomieniu pobierany jest projekt ze [Spring Initializr](https://start.spring.io):

```shell
gradle initSpringBootProject -PoutputDir=/opt/my-projects/my-spring-boot-app --console=plain --info
```

Zostanie wyświetlone:

```text

...

Task name matched 'initSpringBootProject'
Selected primary task 'initSpringBootProject' from project :
Tasks to be executed: [task ':initSpringBootProject']
Tasks that were excluded: []
Resolve mutations for :initSpringBootProject (Thread[included builds,5,main]) started.
:initSpringBootProject (Thread[included builds,5,main]) started.

> Task :initSpringBootProject
Build cache key for task ':initSpringBootProject' is 75b4d5a65d989aa6453584fe39baeab5
Task ':initSpringBootProject' is not up-to-date because:
  No history is available.
Downloading Spring Boot starter project...
Project downloaded to: /opt/my-projects/my-spring-boot-app/starter.zip
Project extracted to: /opt/my-projects/my-spring-boot-app/demo
Stored cache entry for task ':initSpringBootProject' with cache key 75b4d5a65d989aa6453584fe39baeab5

BUILD SUCCESSFUL in 12s
5 actionable tasks: 1 executed, 4 up-to-date
```

Natomiast, przy ponownym uruchomieniu z tym samym parametrem `-PoutputDir`:

```shell
gradle initSpringBootProject -PoutputDir=/opt/my-projects/my-spring-boot-app --console=plain --info
```

Ponieważ dane wyjściowe się nie zmieniły, będzie widoczne:

```text
...

Task name matched 'initSpringBootProject'
Selected primary task 'initSpringBootProject' from project :
Tasks to be executed: [task ':initSpringBootProject']
Tasks that were excluded: []
Resolve mutations for :initSpringBootProject (Thread[Execution worker Thread 4,5,main]) started.
:initSpringBootProject (Thread[Execution worker Thread 4,5,main]) started.

> Task :initSpringBootProject UP-TO-DATE
Build cache key for task ':initSpringBootProject' is 75b4d5a65d989aa6453584fe39baeab5
Skipping task ':initSpringBootProject' as it is up-to-date.

BUILD SUCCESSFUL in 383ms
5 actionable tasks: 5 up-to-date
```

Co potwierdza, że wykorzystany jest incremental build przez oznaczenie taska etykietą `UP-TO-DATE`.

#### Build Cache

Gdy plik `/opt/my-projects/my-spring-boot-app/starter.zip` zostanie skasowany, a task zostanie uruchomiony ponownie:

```shell
gradle initSpringBootProject -PoutputDir=/opt/my-projects/my-spring-boot-app --console=plain --info
```

Z racji tego, że dane wyjściowe wcześniej zostały dodane do lokalnego cache, w odpowiedzi będzie widoczne poniższe:

```text

...

Task name matched 'initSpringBootProject'
Selected primary task 'initSpringBootProject' from project :
Tasks to be executed: [task ':initSpringBootProject']
Tasks that were excluded: []
Resolve mutations for :initSpringBootProject (Thread[included builds,5,main]) started.
:initSpringBootProject (Thread[included builds,5,main]) started.

> Task :initSpringBootProject FROM-CACHE
Build cache key for task ':initSpringBootProject' is 75b4d5a65d989aa6453584fe39baeab5
Task ':initSpringBootProject' is not up-to-date because:
  Output property 'outputDir' file /opt/my-projects/my-spring-boot-app has been removed.
  Output property 'outputDir' file /opt/my-projects/my-spring-boot-app/demo has been removed.
  Output property 'outputDir' file /opt/my-projects/my-spring-boot-app/demo/build.gradle has been removed.
  and more...
Loaded cache entry for task ':initSpringBootProject' with cache key 75b4d5a65d989aa6453584fe39baeab5

BUILD SUCCESSFUL in 416ms
5 actionable tasks: 1 from cache, 4 up-to-date
```

Co mówi o wykorzystaniu lokalnego build cache, potwierdzone przez oznaczenie `FROM-CACHE`. 

{{< admonition success "Wnioski ze ścieżki Gradle Build Cache (DPE University)" >}}
Podczas przerabiania ścieżki [Gradle Build Caching](https://dpeuniversity.gradle.com/app/learning_paths/b82f8dd7-d61e-450f-820e-3e719ef70bee) na [DPE University](https://dpeuniversity.gradle.com/app/catalog) zaciekawiło mnie, jak dokładnie działa lokalny build cache i co właściwie trafia do jego środka. Postanowiłem to rozłożyć na czynniki pierwsze.

Po wykonaniu taska `initSpringBootProject` uwagę zwraca klucz build cache: `75b4d5a65d989aa6453584fe39baeab5`. To archiwum, które znajduje się w katalogu `$GRADLE_USER_HOME/caches/build-cache-1`. Po rozpakowaniu można zobaczyć m.in. plik `METADATA`, który zawiera następujące informacje:

```properties
#Generated origin information
#Sun Jul 13 13:47:46 CEST 2025
executionTime=787
creationTime=1752677283570
identity=\:initSpringBootProject
buildInvocationId=b6ynyhegwjcl5ojld4csg2g7ee
buildCacheKey=75b4d5a65d989aa6453584fe39baeab5
type=org.gradle.api.internal.tasks.execution.TaskExecution
gradleVersion=8.14
```

Natomiast, w folderze `tree-outputDir/` znajduje się zarchiwizowany plik `starter.zip` oraz folder z projektem, czyli dokładnie to, co wcześniej zostało pobrane ze [Spring Initializr](https://start.spring.io/) i zapisane jako wynik działania taska.
{{< /admonition >}}

Więcej o incremental build oraz Build Cache, możesz znaleźć w oficjalnej dokumentacji:

👉 [Incremental build](https://docs.gradle.org/9.0.0/userguide/incremental_build.html).

👉 [Build Cache](https://docs.gradle.org/9.0.0/userguide/build_cache.html).

### Tryb interaktywny

Aby zachować zgodność ze wsparciem incremental build oraz build cache zostało użyte odpowiednio [`upToDateWhen`](https://docs.gradle.org/9.0.0/javadoc/org/gradle/api/tasks/TaskOutputs.html#upToDateWhen(groovy.lang.Closure)) oraz [`cacheIf`](https://docs.gradle.org/9.0.0/javadoc/org/gradle/api/tasks/TaskOutputs.html#cacheIf(org.gradle.api.specs.Spec)).

---

## Gotowość do użytku

[gradle-springinitializr-plugin](https://plugins.gradle.org/plugin/io.oczadly.springinitializr) nie jest tylko hobbystycznym projektem. Traktuję go bardzo poważnie, dlatego też oprócz dodania niezbędnych funkcjonalności zawiera on wszystkie kluczowe aspekty inżynierii oprogramowania, które opisane są w poniższych sekcjach.

### Testy jednostkowe

Zostały napisane w [Spocku](https://spockframework.org). Pokrywają kluczowe funkcjonalności, takie jak walidację, budowanie zapytania do [Spring Initializr](https://start.spring.io) oraz rozpakowywanie. Zgodnie z piramidą testów, jest ich najwięcej w projekcie.

### Testy funkcjonalne

Również napisane w [Spocku](https://spockframework.org) z użyciem [Gradle TestKit](https://docs.gradle.org/9.0.0/userguide/test_kit.html). Do tego testuję odpowiedzi JSON ze [Spring Initializr](https://start.spring.io) z użyciem [WireMock](https://wiremock.org/) zgodne z polecaną oficjalną [dokumentacją](https://docs.spring.io/initializr/docs/current/reference/html/#using-the-stubs) ze [Spring Initializr](https://start.spring.io).

{{< admonition success "Wnioski z używania TestKit w Spocku" >}}
Na początku podczas pracy nad testami funkcjonalnymi natknąłem się na przypadek opisany w dokumentacji TestKit w paragrafie [Controlling the build environment](https://docs.gradle.org/9.0.0/userguide/test_kit.html#sec:controlling_the_build_environment).

Mimo tego, że task `initSpringBootProject` wykonywał się i w logach widziałem:

```text
> Task :initSpringBootProject
Project downloaded to: /private/var/folders/lj/q3_9z0ws4ygb_bvng5vy2vs00000gn/T/spock_initSpringBootProje_0_testProjectDir13964729921630795147/build/generated-project/starter.zip
Project extracted to: /private/var/folders/lj/q3_9z0ws4ygb_bvng5vy2vs00000gn/T/spock_initSpringBootProje_0_testProjectDir13964729921630795147/build/generated-project/demo

BUILD SUCCESSFUL in 3s
1 actionable task: 1 executed
```

To testy nie przechodziły, a ja dostawałem poniższą wiadomość w logach:

```text
Condition not satisfied:

FilesTestUtils.projectFilesExist unzipDir, 'build.gradle', 'src/main/java/com/example/demo/DemoApplication.java'
|              |                 |
|              false             /var/folders/lj/q3_9z0ws4ygb_bvng5vy2vs00000gn/T/spock_initSpringBootProje_0_testProjectDir8148397175690448479/generated-project/demo
class io.oczadly.testsupport.FilesTestUtils
```

Problem z testem wynikał z tego, że [Gradle TestKit](https://docs.gradle.org/9.0.0/userguide/test_kit.html) zawsze uruchamia build w odizolowanym katalogu roboczym wewnątrz `java.io.tmpdir` (np. `/private/var/folders/.../build/`), a nie w katalogu, w którym oczekiwałem plików.

Natomiast w asercji (`generatedProjectDir.absolutePath`) szukałem plików w katalogu tymczasowym [Spocka](https://spockframework.org) (`@TempDir`), który jest innym miejscem niż working directory [TestKit](https://docs.gradle.org/9.0.0/userguide/test_kit.html).

Rozwiązałem to przez:

- [x] Ustawienie `-PoutputDir=${generatedProjectDir.absolutePath}`, które wymuszało, by plugin zapisał pliki tam, gdzie oczekiwał test.
{{< /admonition >}}

### Statyczna analiza kodu

Każde narzędzie przed wypuszczeniem do użytku powinno posiadać mechanizm statycznej analizy kodu. W tym przypadku został użyty [CodeNarc plugin](https://docs.gradle.org/9.0.0/userguide/codenarc_plugin.html) z koniecznym zestawem reguł przydatnych dla narzędzi typu [Gradle](https://gradle.org) plugin.

### Pokrycie kodu testami

Tak, jak zostało wcześniej wspomniane [gradle-springinitializr-plugin](https://plugins.gradle.org/plugin/io.oczadly.springinitializr) jest objęty zarówno testami jednostkowymi, jak i funkcjonalnymi. Pokrycie jest mierzone przy pomocy [JaCoCo plugin](https://docs.gradle.org/9.0.0/userguide/jacoco_plugin.html). Obejmuje oba rodzaje testów i musi przekraczać **80%**.

### Ciągła integracja

Do ciągłej integracji zostało wykorzystane [GitHub Actions](https://github.com/features/actions). Przy każdym PR weryfikowane jest, czy commit jest zgodny z [Conventional Commits](https://www.conventionalcommits.org/en/v1.0.0/). Następnie wykonywane jest `gradle build`. Dzięki temu sprawdzane jest poniższe:

* Kompilacja kodu
* Testy jednostkowe oraz funkcjonalne
* Statyczna analiza kodu
* Pokrycie kodu testami

### Build Scan

Na końcu procesu ciągłej integracji, [Build Scan](https://docs.gradle.org/9.0.0/userguide/build_scans.html) z wykonaniem jest publikowany w https://scans.gradle.com. Przykładowy [Build Scan](https://docs.gradle.org/9.0.0/userguide/build_scans.html) z wykonania można znaleźć [tutaj](https://scans.gradle.com/s/6tu3f64xfst2q).

### Testy kompatybilności

W procesie tworzenia pluginu ważne było, żeby był kompatybilny z różnymi wersjami [Gradle](https://gradle.org) oraz [Kotlin DSL](https://docs.gradle.org/9.0.0/userguide/kotlin_dsl.html) i [Groovy DSL](https://docs.gradle.org/9.0.0/userguide/groovy_build_script_primer.html). Dlatego też przy każdym PR oprócz wcześniej wspomnianych kroków są uruchamiane właśnie testy kompatybilności, które uruchamiają task `initSpringBootProject` na różnych wersjach [Gradle](https://gradle.org) z katalogów:

* `examples/simple-groovy`
* `examples/simple-kotlin`

To wszystko jest możliwe dzięki wykorzystaniu strategii [matrix w GitHub Actions](https://docs.github.com/en/actions/how-tos/write-workflows/choose-what-workflows-do/run-job-variations). Więcej o tym można znaleźć [tutaj](https://docs.github.com/en/actions/how-tos/write-workflows/choose-what-workflows-do/run-job-variations).

### Ciągłe dostarczanie

Po wcześniej opisanym procesie ciągłej integracji, gdy commit trafia do main'a uruchamiane jest [GitHub Actions](https://github.com/features/actions), które wykorzystuje [semantic-release](https://semantic-release.gitbook.io/semantic-release/) do zarządzania zmianami w `CHANGELOG.md`, tworzenia nowego taga wraz z releasem w repozytorium oraz publikowania pluginu do [Gradle - Plugins](https://plugins.gradle.org/).

---

## Podsumowanie

Tworząc [gradle-springinitializr-plugin](https://plugins.gradle.org/plugin/io.oczadly.springinitializr) miałem nie tylko radość z odwzorowania `gradle init` dla [Spring Boot](https://spring.io/projects/spring-boot), przerabiania kursów [DPE University](https://dpeuniversity.gradle.com/app/catalog) poznania API [Spring Initializr](https://start.spring.io), [najlepszych praktyk Gradle](https://docs.gradle.org/9.0.0/userguide/best_practices_general.html), [Spock](https://spockframework.org/spock/docs/1.0/spock_primer.html) i [Groovy](https://groovy-lang.org/style-guide.html), ale jestem w pełni zadowolony z efektu końcowego. To nie jest przykład kolejnego pluginu. To narzędzie **gotowe do użycia** lokalnie i jako element platformy przygotowane świadomie, solidnie i podążające za najlepszymi wzorcami.

Dla Platform Engineerów to gotowy asset do platformy, dla Software Engineerów – szybki start w codziennej pracy, a dla eksplorujących – praktyczny wzorzec budowy pluginu Gradle.

{{< admonition example "Co dalej?" >}}
Zainteresowany rozwojem pluginu?

👉 Zobacz, jak możesz uczestniczyć w jego rozwoju i przejrzyj plik [CONTRIBUTING](https://github.com/paweloczadly/gradle-springinitializr-plugin/blob/main/CONTRIBUTING.md).

Masz pomysł na nową funkcję lub znalazłeś buga?

👉 Zgłoś swój pomysł albo zaraportuj błąd [tutaj](https://github.com/paweloczadly/gradle-springinitializr-plugin/issues).
{{< /admonition >}}

{{< buymeacoffee >}}
