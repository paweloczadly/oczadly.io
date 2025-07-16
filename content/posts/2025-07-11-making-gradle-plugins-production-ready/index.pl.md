---
title: "gradle init dla Spring Boot"
subtitle: "Produkcyjny plugin Gradle inspirowany praktykami z DPE University."
date: 2025-07-11
description: "Produkcyjny plugin Gradle inspirowany praktykami z DPE University."
draft: false
resources:
- name: "featured-image"
  src: "featured-image.png"
- name: "install.sh"
  src: install.sh
---

Do you like this blog and my work? {{< buymeacoffee >}}

## Dlaczego kolejny plugin Gradle

Ostatnio chciałem poszerzyć swoją wiedzę o [Build Scanach](https://docs.gradle.org/8.14.3/userguide/build_scans.html), [Develocity](https://gradle.com/develocity/) i ich praktycznym zastosowaniu, dlatego zacząłem przerabiać kursy na naszej platformie [DPE University](https://dpeuniversity.gradle.com/app/catalog). Na co dzień mam styczność z [Develocity](https://gradle.com/develocity/) od strony operacyjnej i produkcyjnej – utrzymuję między innymi [instancje open source](https://github.com/gradle/develocity-oss-projects), więc zależało mi na lepszym zrozumieniu produktu, a zwłaszcza użycia od strony użytkowników, w mojej codziennej pracy inżyniera.

Aby usystematyzować zdobytą wiedzę, postanowiłem zbudować projekt zgodny z best practices omawianymi na kursach. Równolegle pracowałem nad mikroserwisem w [Spring Boot](https://spring.io/projects/spring-boot), generowanym ze [Spring Initializr](https://start.spring.io/), i zauważyłem brak [pluginu Gradle](https://docs.gradle.org/current/userguide/plugins.html), który automatyzowałby ten proces w sposób przyjazny build cache i CI/CD.

Tak powstał [gradle-springinitializr-plugin](#) – narzędzie gotowe do użycia na produkcji, które ułatwia bootstrapowanie projektów [Spring Boot](https://spring.io/projects/spring-boot) z poziomu [Gradle](https://gradle.org/). Ten wpis jest o tym, jak powstał, jak działa i jak możesz go wykorzystać, aby przyspieszyć start nowych projektów w swoim zespole.

{{< admonition example "Szybki start" >}}
Plugin jest open source i dostępny w [Gradle Plugin Portal](#) – możesz od razu go zainstalować i używać:
Dodaj go globalnie w `~/.gradle/init.d`:

```bash
$ curl -fsSL https://oczadly.io/2025-07-11-making-gradle-plugins-production-ready/install.sh | bash
```

Dzięki temu będziesz mógł generować kolejne projekty [Spring Boot](https://spring.io/projects/spring-boot) z [Gradle](https://gradle.org/) od razu podczas czytania wpisu, przyspieszając swój onboarding i codzienną pracę.

👉 [GitHub](#)

👉 [Gradle Plugin Portal](#)

Jeśli chcesz usunąć plugin, usuń plik `~/.gradle/init.d/spring-initializr.gradle`.
{{< /admonition >}}

Przy okazji chciałem stworzyć referencyjny, plugin [Groovy](https://groovy-lang.org/) gotowy do użycia na produkcji, zgodny z [Gradle](https://gradle.org/) best practices oraz pełnym pipelinem CI/CD, aby mieć gotowy szablon pod kolejne pluginy, które będę budować w przyszłości.

---

## Dla kogo

**Dla Platform Engineerów**

[gradle-springinitializr-plugin](#) może stać się elementem Waszej platformy, który przyspieszy scaffolding mikroserwisów w organizacji. Dzięki niemu możecie:

✅ Szybko generować mikroserwisy [Spring Boot](https://spring.io/projects/spring-boot) ([Groovy](https://groovy-lang.org/)/[Java](https://www.java.com/)/[Kotlin](https://kotlinlang.org/), [Gradle](https://gradle.org/)/[Maven](https://maven.apache.org/)) z CLI, pipeline’ów lub automatycznych procesów [GitOps](https://www.gitops.tech/).

✅ Generować projekty zawsze z aktualną wersją Spring Boot, Javy i dependencies, eliminując ręczne utrzymywanie szablonów.

✅ Zapewnić build cache aware i CI-friendly workflow od samego początku projektu.

✅ Standaryzować strukturę projektów, metadane (groupId, artifactId, packageName, description) i proces tworzenia mikroserwisów.

Jeśli budujecie platformę inżynierską dla zespołów developerskich w ekosystemie JVM, ten plugin może stać się Waszym lekko konfigurowalnym, automatyzowalnym elementem pipeline do "just-in-time" scaffolding projektów Spring Boot.

**Dla Software Engineerów**

[gradle-springinitializr-plugin](#) może stać się Waszym go-to narzędziem do szybkiego startu projektów Spring Boot bez opuszczania ekosystemu Gradle.
Zamiast klikania w webowe UI Spring Initializr czy pisania curl generujecie w pełni konfigurowalny projekt jedną komendą Gradle.
To oszczędność czasu, spójność konfiguracji i od razu wpięcie w Wasz workflow build cache, CI/CD oraz konwencje zespołowe.

**Dla osób ciekawych i świadomych**

[gradle-springinitializr-plugin](#) pozwoli Wam w jedną minutę zobaczyć, jak wygląda proces generowania Spring Boot z poziomu Gradle, bez klikania po start.spring.io czy pisania curli. Zamiast ręcznego ściągania ZIP-ów, od razu startujesz projekt lokalnie i możesz eksplorować Spring Boot w sposób powtarzalny, czysty i przyjazny.

---

## Jak działa

Po zainstalowaniu gradle-springinitializr-plugin możesz generować projekty Spring Boot bezpośrednio z Gradle, bez opuszczania terminala.

Plugin udostępnia pojedynczy task initSpringBootProject, który pobiera projekt z Spring Initializr i następnie rozpakowuje go. Zamiast klikać w interfejs webowy, wystarczy uruchomić:

```bash
$ gradle initSpringBootProject
```

Otrzymasz:

```text
> Task :initSpringBootProject
Downloading Spring Boot starter project...
Project downloaded to: /opt/my-projects/build/generated-project/starter.zip
Project extracted to: /opt/my-projects/build/generated-project/demo

BUILD SUCCESSFUL in 1s
```

Domyślnie projekt zostanie pobrany i rozpakowany do build/generated-project/, gotowy do otwarcia i uruchomienia.

Plugin pozwala także ustawić dowolny parametr dostępny w Spring Initializr:

```bash
$ gradle initSpringBootProject \
    -PprojectType=gradle-project-kotlin \
    -Planguage=kotlin \
    -PbootVersion=4.0.0-SNAPSHOT \
    -PgroupId=com.mycompany \
    -PartifactId=my-spring-app \
    -PprojectName="My Spring App" \
    -PprojectDescription="My Spring Boot application generated via gradle-springinitializr-plugin" \
    -PpackageName=com.mycompany.myspringapp \
    -Ppackaging="war" \
    -PjavaVersion="21" \
    -PoutputDir="/opt/my-projects/my-spring-boot-app"
```

Dzięki temu możesz generować czyste, spójne projekty, gotowe do pracy w Twoim workflow CI/CD i zgodne z zespołowymi konwencjami – bez manualnych kroków.

---

## Jak został zbudowany

Jak wspomniałem wcześniej, poza wykorzystaniem wiedzy z kursów DPE University, chciałem, aby ten plugin był **referencyjną implementacją** pod budowę kolejnych pluginów. Moim celem było stworzenie czegoś solidnego, ponadczasowego i niemal bezobsługowego.

### `plugin.properties`

Sercem pluginu jest plik `plugin.properties`, który zawiera domyślne wartości parametrów oraz fallbacki (na wypadek braku dostępności metadata API). Dzięki temu, jeśli w przyszłości będę musiał dodać nowe wersje Spring Boot lub typy projektów, nie będę musiał zmieniać kodu – wystarczy aktualizacja pliku properties.

W trakcie pracy nad testami funkcjonalnymi okazało się, że żeby `plugin.properties` był dostępny jako zasób, trzeba dodać do `build.gradle` następujący wpis:

```groovy
sourceSets {
    functionalTest {
        resources.srcDir file('src/main/resources')
    }
}
```

### `convention` dla URL i metadata endpoint

Adres URL do Spring Initializr oraz endpoint do pobierania wspieranych wersji Spring Boot, typów projektów i języków zostały zaprojektowane jako **konfiguracja pluginu jako całości** - można je traktować jako ustawienia globalne. Nie dotyczą konkretnego wywołania task `initSpringBootProject`. Określają one **skąd** są pobierane dane, a nie **co** ma być w projekcie.

Więcej o endpoint'cie do pobierania wspieranych opcji w dalszej części wpisu.

Plugin stosuje domyślne wartości adresu URL dla Spring Initializr oraz endpointu metadata przy użyciu mechanizmu [`convention(...)`](https://docs.gradle.org/8.14.3/userguide/lazy_configuration.html#applying_conventions) w Gradle, który pozwala ustawić wartość domyślną, ale umożliwia jej nadpisanie przez użytkownika w razie potrzeby. Dzięki temu buildy pozostają czyste i przewidywalne, zachowując elastyczność, gdy jest potrzebna.

Przy próbie nadpisania przez `-PinitializrUrl=https://your-initializr.example.com`, plugin i tak użyje domyślnej wartości https://start.spring.com. Wynika to z tego, że `initializrUrl` traktowane jest jako konfiguracja pluginu, a nie dane wejściowe użytkownika.

Możesz jednak łatwo nadpisać te wartości w swoim `build.gradle`:

```groovy
plugins {
    id 'io.oczadly.springinitializr' version '1.3.0'
}

task initSpringBootProject {
    initializrUrl = 'https://your-initializr.example.com'
    metadataEndpoint = '/yours'
}
```

Zobacz oficjalną [dokumentację Gradle dotyczącą `convention(...)`](https://docs.gradle.org/current/userguide/lazy_configuration.html#applying_conventions), aby dowiedzieć się, jak ustawiać przejrzyste, nadpisywalne wartości domyślne we własnych pluginach i taskach.

### Wyciąganie dostępnych opcji z Metadata API

Jak już wcześniej wspomniałem, plugin pobiera wspierane wersje między innymi Spring Boot, typów projektu oraz języków, w których można programować aplikacje po pobraniu ze Spring Initializr. Jest to dostępne przy użyciu [Metadata endpoint](https://docs.spring.io/initializr/docs/current/reference/html/#metadata-format). Dzięki temu nie ma potrzeby ciągłego aktualizowania pluginu o wspierane parametry.

Podczas dodawania wspieranych typów projektów oraz języków natknąłem się na ciekawy problem z użyciem [configuration cache](https://docs.gradle.org/8.14.2/userguide/configuration_cache.html) w Gradle. O którym poniżej.

{{< admonition success "Wnioski z używania --configuration-cache" >}}
Na początku napotkałem kilka problemów podczas testowania pluginu z flagą `--configuration-cache`. Początkowo sądziłem, że problem wynika z odczytu `plugin.properties`, ale prawdziwą przyczyną było korzystanie z API `project.*` wewnątrz metody `@TaskAction`:

```groovy
package io.oczadly.tasks

abstract class InitSpringBootProjectTask extends DefaultTask {

  @Internal
  final ListProperty<String> supportedProjectTypes = project.objects.listProperty String

  @Internal
  final ListProperty<String> supportedLanguages = project.objects.listProperty String

  /* Pozostały mało znaczący kod */
}
```

To łamie mechanizm configuration cache, ponieważ Gradle wymaga, aby wszystkie dane wejściowe były jawnie zadeklarowane przy użyciu `Property<T>`, `Provider<T>` lub `DirectoryProperty`. Następnie w fazie wykonania nie można odwoływać się do zmiennego stanu projektu.

Rozwiązałem to w następujący sposób:

- [x] Przeniesienie całej logiki konfiguracyjnej do fazy `apply()`.

- [x] Wykorzystanie `project.providers.gradleProperty(...)` do podłączenia danych wejściowych użytkownika przez Providers.

- [x] Ustawianie wartości domyślnych przy użyciu `set(...)` i `convention(...)`.

- [x] Upewnienie się, że `@TaskAction` operuje wyłącznie na właściwościach deklarowanych jako `Property<T>` lub `Provider<T>`, czyli ocenianych dopiero w czasie wykonania.

Ta zmiana nie tylko umożliwiła zgodność pluginu z configuration cache, ale też doprowadziła do czystszej, bardziej idiomatycznej implementacji zgodnej z praktykami Gradle.

Zobacz oficjalną [dokumentację Gradle dotyczącą configuration cache](https://docs.gradle.org/8.14.2/userguide/configuration_cache.html), aby poznać wszystkie szczegóły i ograniczenia.
{{< /admonition >}}


### Parametry `-P` i mechanizm walidacji

Plugin akceptuje wszystkie parametry dostępne na stronie https://start.spring.io - te same, które możesz ustawić w webowym UI Spring Initializr.

| Parametr             | Pole w Spring Initializr               | Domyślna wartość                 |
| -------------------- | -------------------------------------- | -------------------------------- |
| `projectType`        | Project                                | **Gradle**                       |
| `language`           | Language                               | **Java**                         |
| `bootVersion`        | Spring Boot                            | **3.5.3**                        |
| `groupId`            | Group w sekcji Project Metadata        | **com.example**                  |
| `artifactId`         | Artifact w sekcji Project Metadata     | **demo**                         |
| `projectName`        | Name w sekcji Project Metadata         | **demo**                         |
| `projectDescription` | Description w sekcji Project Metadata  | **Demo project for Spring Boot** |
| `packageName`        | Package name w sekcji Project Metadata | **com.example.demo**             |
| `packaging`          | Packaging w sekcji Project Metadata    | **Jar**                          |
| `javaVersion`        | Java w sekcji Project Metadata         | **17**                           |

W przypadku, gdy wartość nie jest przekazana do taska, na przykład:

```shell
$ gradle initSpringBootProject
```

Zostaną użyte domyślne wartości z pliku `plugin.properties`:

```properties
task.initSpringBootProject.property.projectType.default=gradle-project
task.initSpringBootProject.property.language.default=java
task.initSpringBootProject.property.bootVersion.default=3.5.3
task.initSpringBootProject.property.groupId.default=com.example
task.initSpringBootProject.property.artifactId.default=demo
task.initSpringBootProject.property.projectName.default=Demo
task.initSpringBootProject.property.projectDescription.default=Demo project for Spring Boot
task.initSpringBootProject.property.packageName.default=com.example.demo
task.initSpringBootProject.property.packaging.default=jar
task.initSpringBootProject.property.javaVersion.default=17
```

Po ustawieniu przez użytkowników parametrów albo przypisania domyślnych wartości, w tasku `initSpringBootProject` jest robiona walidacja. Task na początku pobiera listę wspieranych wersji Spring Boot, typów projektu oraz języków z endpointu Metadata. A jeśli API nie jest dostępne, używa wartości fallback z pliku `plugin.properties`:

```properties
task.initSpringBootProject.property.projectType.fallback=gradle-project,gradle-project-kotlin,maven-project
task.initSpringBootProject.property.language.fallback=groovy,kotlin,java
task.initSpringBootProject.property.bootVersion.fallback=4.0.0-SNAPSHOT,3.5.4-SNAPSHOT,3.5.3,3.4.8-SNAPSHOT,3.4.7
task.initSpringBootProject.property.packaging.fallback=jar,war
task.initSpringBootProject.property.javaVersion.fallback=24,21,17
```

Jeśli użytkownik poda błędną wartość parametru, która nie jest wspierana task zakończy się błędem. Na przykład:

```shell
$ gradle initSpringBootProject -Planguage=clojure
```

Dostanie komunikat:

```text
> Task :initSpringBootProject FAILED

FAILURE: Build failed with an exception.

* What went wrong:
Execution failed for task ':initSpringBootProject'.
> Unsupported language: 'clojure'. Supported options: [groovy, java, kotlin]

* Try:
> Run with --stacktrace option to get the stack trace.
> Run with --info or --debug option to get more log output.
> Run with --scan to get full insights.
> Get more help at https://help.gradle.org.

BUILD FAILED in 5s
```

### Incremental build i build cache

Na podstawie ścieżki [Gradle Build Caching](https://dpeuniversity.gradle.com/app/learning_paths/b82f8dd7-d61e-450f-820e-3e719ef70bee) na DPE University oraz wiedzy tam nabytej w pluginie zostało dodane wsparcie do [incremental build](https://docs.gradle.org/8.14.3/userguide/incremental_build.html) oraz [Build Cache](https://docs.gradle.org/8.14.3/userguide/build_cache.html). Dzięki temu kolejne uruchomienia są natychmiastowe, a rezultaty mogą być ponownie użyte.

Task `initSpringBootProject` deklaruje zarówno dane wejściowe (`@Input`), jak i dane wyjściowe (`@OutputDirectory` - w tym przypadku `outputDir`, powiązany z `DirectoryProperty`). To zgodne z definicją poprawnie skonfigurowanego taska w Gradle, opisaną [tutaj](https://docs.gradle.org/8.14.3/userguide/incremental_build.html#sec:task_inputs_outputs).

Dzięki temu Gradle ma pełną kontrolę nad śledzeniem stanu wejść i wyjść, co umożliwia:

* Pomijanie taska (`UP-TO-DATE`), jeśli dane wyjściowe się nie zmieniły - incremental build.
* Przywrócenie wyników (`FROM-CACHE`), jeśli dane wyjściowe są w lokalnym cache - build cache.

Poniżej znajduje się przykład, jak task zachowuje się w obu przypadkach.

#### Incremental build

Przy pierwszym uruchomieniu pobierany jest projekt ze Spring Initializr:

```shell
$ gradle initSpringBootProject -PoutputDir=/opt/my-projects/my-spring-boot-app --console=plain --info
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
$ gradle initSpringBootProject -PoutputDir=/opt/my-projects/my-spring-boot-app --console=plain --info
```

Z racji tego, że dane wyjściowe się nie zmieniły, będzie widoczne:

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
$ gradle initSpringBootProject -PoutputDir=/opt/my-projects/my-spring-boot-app --console=plain --info
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
Podczas przerabiania ścieżki [Gradle Build Caching](https://dpeuniversity.gradle.com/app/learning_paths/b82f8dd7-d61e-450f-820e-3e719ef70bee) na DPE University zaciekawiło mnie, jak dokładnie działa lokalny build cache i co właściwie trafia do jego środka. Postanowiłem to rozłożyć na czynniki pierwsze.

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

W folderze `tree-outputDir/` znajduje się zarchiwizowany plik `starter.zip` oraz folder z projektem, czyli dokładnie to, co wcześniej zostało pobrane ze Spring Initializr i zapisane jako wynik działania taska.
{{< /admonition >}}

Więcej o incremental build oraz Build Cache, możesz znaleźć w oficjalnej dokumentacji:

👉 [Incremental build](https://docs.gradle.org/8.14.3/userguide/incremental_build.html).

👉 [Build Cache](https://docs.gradle.org/8.14.3/userguide/build_cache.html).
