---
title: "gradle init for Spring Boot"
subtitle: "Production-ready Gradle plugin inspired by DPE University courses."
date: 2025-08-28
description: "Production-ready Gradle plugin inspired by DPE University courses."
draft: false
resources:
- name: "featured-image"
  src: "featured-image.png"
- name: "install.sh"
  src: install.sh
---

## Why yet another Gradle plugin

Recently, I wanted to deepen my understanding of [Build Scans](https://docs.gradle.org/9.0.0/userguide/build_scans.html), [Develocity](https://gradle.com/develocity/), and their practical applications, so I started going through the courses on our [DPE University](https://dpeuniversity.gradle.com/app/catalog) platform. In my daily work, I interact with [Develocity](https://gradle.com/develocity/) from the operational and production side — maintaining [open-source instances](https://github.com/gradle/develocity-oss-projects) among other things — so I wanted to better understand the product, especially from the end-user perspective, to support my daily engineering work.

To systematize what I was learning, I decided to build a project that aligns with the best practices discussed in these courses. At the same time, I was working on a [Spring Boot](https://spring.io/projects/spring-boot) microservice generated via [Spring Initializr](https://start.spring.io) and noticed there was no [Gradle plugin](https://docs.gradle.org/9.0.0/userguide/plugins.html) that would automate this process in a way that is build cache-friendly and CI/CD-friendly.

That’s how the [gradle-springinitializr-plugin](https://plugins.gradle.org/plugin/io.oczadly.springinitializr) was born—a production-ready tool that simplifies bootstrapping [Spring Boot](https://spring.io/projects/spring-boot) projects directly from [Gradle](https://gradle.org/). This post covers how it was built, how it works, and how you can use it to speed up starting new projects within your team.

{{< admonition example "Quick start" >}}
The plugin is open-source and available on the [Gradle - Plugins](https://plugins.gradle.org/plugin/io.oczadly.springinitializr). You can install and start using it right away.

Create the `build.gradle` file and add the following:

```groovy
plugins {
    id 'io.oczadly.springinitializr' version '1.0.0'
}
```

Create the `settings.gradle` file and add this configuration:

```groovy
rootProject.name = 'examples-simple-groovy'
```

Or add it to your existing project.

This way, you can generate new [Spring Boot](https://spring.io/projects/spring-boot) projects with [Gradle](https://gradle.org/) while reading this post, accelerating your onboarding and daily work.

👉 [Gradle - Plugins](https://plugins.gradle.org/plugin/io.oczadly.springinitializr)

👉 [GitHub](https://github.com/paweloczadly/gradle-springinitializr-plugin)
{{< /admonition >}}

I treat this plugin as a reference: how to build a production-ready plugin in [Groovy](https://groovy-lang.org/) consistent with [Gradle best practices](https://docs.gradle.org/9.0.0/userguide/best_practices_general.html). If you build plugins yourself, you can use it as a point of reference.

---

## Who is this plugin for

**Platform Engineers**

[gradle-springinitializr-plugin](https://plugins.gradle.org/plugin/io.oczadly.springinitializr) can become a part of your platform to accelerate microservice scaffolding across your organization. With it, you can:

✅ Quickly generate [Spring Boot](https://spring.io/projects/spring-boot) microservices ([Groovy](https://groovy-lang.org/)/[Java](https://www.java.com/)/[Kotlin](https://kotlinlang.org/), [Gradle](https://gradle.org/)/[Maven](https://maven.apache.org/)) from CLI, pipelines, or automated [GitOps](https://www.gitops.tech/) processes.

✅ Always generate projects with the latest [Spring Boot](https://spring.io/projects/spring-boot), [Java](https://www.java.com/), and dependency versions, eliminating the need to manually maintain templates.

✅ Provide a build cache-aware, CI-friendly workflow from day one of your projects.

✅ Standardize project structure, metadata (groupId, artifactId, packageName, description), and the microservice creation process.

If you are building an engineering platform for JVM-based developer teams, this plugin can become a lightweight, configurable, and automatable pipeline element for "just-in-time" scaffolding of [Spring Boot](https://spring.io/projects/spring-boot) projects.

**Software Engineers**

[gradle-springinitializr-plugin](https://plugins.gradle.org/plugin/io.oczadly.springinitializr) can become your go-to tool for quickly starting [Spring Boot](https://spring.io/projects/spring-boot) projects without leaving the [Gradle](https://gradle.org/) ecosystem.
Instead of clicking through the [Spring Initializr](https://start.spring.io) web UI or writing curl commands, you can generate a fully customizable project with a single [Gradle](https://gradle.org/) command.
It saves time, ensures consistent configurations, and integrates immediately into your build cache, CI/CD, and team conventions.

**The Curious and Mindful**

[gradle-springinitializr-plugin](https://plugins.gradle.org/plugin/io.oczadly.springinitializr) lets you see how [Spring Boot](https://spring.io/projects/spring-boot) project generation from [Gradle](https://gradle.org/) works in under a minute, without clicking around https://start.spring.io or writing curl commands. Instead of manually downloading ZIP files, you can instantly start a project locally and explore [Spring Boot](https://spring.io/projects/spring-boot) in a repeatable, clean, and user-friendly way.

---

## How it works

After installing the [gradle-springinitializr-plugin](https://plugins.gradle.org/plugin/io.oczadly.springinitializr), you can generate [Spring Boot](https://spring.io/projects/spring-boot) projects directly from [Gradle](https://gradle.org/) without leaving your terminal.

The plugin provides a single task `initSpringBootProject`, which downloads a project from [Spring Initializr](https://start.spring.io) and extracts it. Instead of clicking in the web interface, simply run:

```shell
gradle initSpringBootProject
```

You will get:

```text
> Task :initSpringBootProject
Downloading Spring Boot starter project...
Project downloaded to: /opt/my-projects/build/generated-project/starter.zip
Project extracted to: /opt/my-projects/build/generated-project/demo

BUILD SUCCESSFUL in 1s
```

By default the project will be downloaded and extracted into `build/generated-project/demo`, ready to open and run.

The plugin also allows you to set any parameter available in [Spring Initializr](https://start.spring.io):

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

This way you generate clean, consistent projects ready for your CI/CD workflow and aligned with team conventions – without manual steps.

The plugin also supports an experimental interactive mode inspired by `gradle init`:

![gradle init dla Spring Boot](https://raw.githubusercontent.com/paweloczadly/gradle-springinitializr-plugin/refs/tags/v1.0.0/docs/images/demo.gif "gradle init for Spring Boot")

This allows you to enter all project parameters without remembering command line flags – the plugin guides you step by step through choosing [Spring Boot](https://spring.io/projects/spring-boot) version, language, project type, and dependencies. It’s particularly useful for new team members or when you want to quickly prepare a project aligned with your organization’s standards.

{{< admonition warning "WARNING" >}}
Interactive mode is still experimental — great for learning and quick start. In CI/CD pipelines I recommend explicit -P flags.
{{< /admonition >}}

To use interactive mode, follow the instructions in the [FAQ](https://github.com/paweloczadly/gradle-springinitializr-plugin/blob/v1.0.0/FAQ.md#is-interactive-mode-supported).

---

## How it’s built

As mentioned earlier, besides using knowledge from [DPE University](https://dpeuniversity.gradle.com/app/catalog), I wanted this plugin to be a **reference implementation** for building further plugins. My goal was to create something solid, nearly maintenance-free, and as timeless as possible.

### `plugin.properties`

The heart of the plugin is the `plugin.properties` file, which contains default parameter values. This supports the principle of _separating code and configuration_ - changes to values do not require code modification or recompilation, just file replacement.

Properties are loaded once at plugin startup and available through static constants:

```groovy
PluginConfig.getOrThrow(PluginConstants.PLUGIN_ID)
```

This approach simplifies both production and test configuration – giving full control over the environment without changes to plugin logic.

{{< admonition success "Lessons from functional tests" >}}
For `plugin.properties` to be visible in functional tests as a resource, add to `build.gradle`:

```groovy
sourceSets {
    functionalTest {
        resources.srcDir file('src/main/resources')
    }
}
```

This way functional tests use exactly the same configuration as the production plugin.
{{< /admonition >}}

### `convention`: clean plugin configuration

Options such as `initializrUrl`, `metadataEndpoint` and `extract` are designed as **global plugin configuration** – they concern the source of data (*where* to fetch the project from), not the project content itself (*what* it should include). This keeps separation between infrastructural configuration and actual generation logic.

Default values are set using [`convention(...)`](https://docs.gradle.org/9.0.0/userguide/lazy_configuration.html#applying_conventions) in [Gradle](https://gradle.org) - which means:

* the user *does not have to set anything* to use the plugin in default mode,
* but *can override* any value in build.gradle, for example to use their own [Spring Initializr](https://start.spring.io) instance or disable ZIP extraction:

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

This approach provides:

* **clean builds** – no mixing of configuration with invocation parameters.
* **predictability** – the plugin always works on explicitly defined inputs.
* **flexibility** – the user can point to a custom endpoint, e.g. in CI or a mirror.

See [official Gradle documentation on `convention(...)`](https://docs.gradle.org/9.0.0/userguide/lazy_configuration.html#applying_conventions) for more details on setting clear, overridable defaults in your plugins and tasks.

### Extracting available options from Metadata API

The plugin fetches supported versions of [Spring Boot](https://spring.io/projects/spring-boot), project types, and languages available after downloading from [Spring Initializr](https://start.spring.io). This is done via the [Metadata endpoint](https://docs.spring.io/initializr/docs/current/reference/html/#project-metadata). Thanks to this, there is no need to constantly update the plugin for supported parameters.

While adding supported project types and languages I encountered an interesting issue with [configuration cache](https://docs.gradle.org/9.0.0/userguide/configuration_cache.html) in [Gradle](https://gradle.org/). More on this below.

{{< admonition success "Lessons from using –configuration-cache" >}}
At first I ran into problems testing the plugin with the `--configuration-cache` flag. Initially I thought the issue was reading `plugin.properties`, but the real cause was using the `project.*` API in the class extending `DefaultTask`:

```groovy
package io.oczadly.tasks

abstract class InitSpringBootProjectTask extends DefaultTask {

  @Internal
  final ListProperty<String> supportedProjectTypes = project.objects.listProperty String

  @Internal
  final ListProperty<String> supportedLanguages = project.objects.listProperty String

  @TaskAction
  void download() {
    /* Remaining code omitted for clarity */
  }
}
```

This breaks [configuration cache](https://docs.gradle.org/9.0.0/userguide/configuration_cache.html), because [Gradle](https://gradle.org/) requires all inputs to be explicitly declared using `Property<T>`, `Provider<T>` or `DirectoryProperty`. Then during execution phase you cannot refer to mutable project state.

I solved this by:

- [x] Moving all logic of fetching supported project types and languages into the download() method.
- [x] Ensuring that `@TaskAction` operates only on properties declared as `Property<T>` or `Provider<T>`, evaluated at execution time.

This change not only enabled [configuration cache](https://docs.gradle.org/9.0.0/userguide/configuration_cache.html) compatibility, but also led to a cleaner, more idiomatic implementation aligned with [Gradle](https://gradle.org/) practices.

See [official Gradle documentation on configuration cache](https://docs.gradle.org/9.0.0/userguide/configuration_cache.html) for all details and limitations.
{{< /admonition >}}

### `-P` parameters and validation mechanism

The plugin accepts all parameters available at https://start.spring.io — the same ones you can set in the web UI of [Spring Initializr](https://start.spring.io).

After users set parameters or default values are assigned, validation is performed inside the `initSpringBootProject` task. At the beginning, the task fetches the list of supported [Spring Boot](https://spring.io/projects/spring-boot) versions, project types, and languages from the [Metadata endpoint](https://docs.spring.io/initializr/docs/current/reference/html/#project-metadata). If a user provides an invalid parameter value that is not supported, the task will fail. For example:

```shell
gradle initSpringBootProject -Planguage=clojure
```

Will result in the message:

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

### Incremental build and build cache

Based on the [Gradle Build Caching path](https://dpeuniversity.gradle.com/app/learning_paths/b82f8dd7-d61e-450f-820e-3e719ef70bee) at [DPE University](https://dpeuniversity.gradle.com/app/catalog) and the knowledge gained there, the plugin was given support for [incremental build](https://docs.gradle.org/9.0.0/userguide/incremental_build.html) and [Build Cache](https://docs.gradle.org/9.0.0/userguide/build_cache.html). Thanks to this, subsequent executions are instant, and results can be reused.

The `initSpringBootProject` task declares both inputs (`@Input`) and outputs (`@OutputDirectory` — in this case `outputDir`, tied to a `DirectoryProperty`). This is aligned with the definition of a correctly configured task in [Gradle](https://gradle.org), described here.

Thanks to this, [Gradle](https://gradle.org) has full control over tracking the state of inputs and outputs, which enables:

* Skipping the task (`UP-TO-DATE`) if the outputs have not changed — incremental build.
* Restoring results (`FROM-CACHE`) if outputs exist in the local cache — build cache.

Below is an example of how the task behaves in both cases.

#### Incremental build

On the first run, the project is downloaded from [Spring Initializr](https://start.spring.io):

```shell
gradle initSpringBootProject -PoutputDir=/opt/my-projects/my-spring-boot-app --console=plain --info
```

You will see:

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

On subsequent runs with the same `-PoutputDir` parameter:

```shell
gradle initSpringBootProject -PoutputDir=/opt/my-projects/my-spring-boot-app --console=plain --info
```

Since the outputs haven’t changed, you’ll see:

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

Which confirms that incremental build was used, marked with the `UP-TO-DATE` label.

#### Build cache

If the file `/opt/my-projects/my-spring-boot-app/starter.zip` is deleted and the task is run again:

```shell
gradle initSpringBootProject -PoutputDir=/opt/my-projects/my-spring-boot-app --console=plain --info
```

Since the outputs were previously added to the local cache, the response will show:

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

This confirms that the local build cache was used, indicated by the `FROM-CACHE` label.

{{< admonition success "Lessons from the Gradle Build Cache path (DPE University" >}}
While going through the [Gradle Build Caching path](https://dpeuniversity.gradle.com/app/learning_paths/b82f8dd7-d61e-450f-820e-3e719ef70bee) at [DPE University](https://dpeuniversity.gradle.com/app/catalog), I became curious about how exactly the local build cache works and what actually goes inside it. I decided to break it down.

After running the `initSpringBootProject` task, the build cache key `75b4d5a65d989aa6453584fe39baeab5` stands out. That’s an archive located in `$GRADLE_USER_HOME/caches/build-cache-1`. When unpacked, you can see, among others, a `METADATA` file that contains:

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

In the `tree-outputDir/` folder there is the archived `starter.zip` file and the project folder — exactly what was previously downloaded from [Spring Initializr](https://start.spring.io) and saved as the task’s outputs.
{{< /admonition >}}

For more on incremental build and Build Cache, see the official documentation:

👉 [Incremental build](https://docs.gradle.org/9.0.0/userguide/incremental_build.html).

👉 [Build Cache](https://docs.gradle.org/9.0.0/userguide/build_cache.html).

### Interactive mode

To preserve compatibility with incremental build and build cache, `upToDateWhen` and `cacheIf` were used accordingly.

---

## Production readiness

When building this plugin I wanted it to be **ready for production use** from day one. That means not just "it works on my machine", but it is tested, validated, analyzable, and integrated with CI/CD.

### Unit tests

Written in [Spock](https://spockframework.org). They cover key functionalities such as parameter validation, building queries to [Spring Initializr](https://start.spring.io), and extraction. In line with the testing pyramid, these are the most numerous tests in the project.

### Functional tests

Also written in [Spock](https://spockframework.org), this time using [Gradle TestKit](https://docs.gradle.org/9.0.0/userguide/test_kit.html). In addition, I test JSON responses from [Spring Initializr](https://start.spring.io) with [WireMock](https://wiremock.org/), following the official [documentation](https://docs.spring.io/initializr/docs/current/reference/html/#using-the-stubs) recommended by the [Spring Initializr](https://start.spring.io) team.

{{< admonition success "Lessons from using TestKit in Spock" >}}
At the beginning, while working on functional tests, I ran into a case described in the TestKit documentation in the section [Controlling the build environment](https://docs.gradle.org/9.0.0/userguide/test_kit.html#sec:controlling_the_build_environment).

Even though the `initSpringBootProject` task executed successfully and in the logs I could see:

```text
> Task :initSpringBootProject
Project downloaded to: /private/var/folders/lj/q3_9z0ws4ygb_bvng5vy2vs00000gn/T/spock_initSpringBootProje_0_testProjectDir13964729921630795147/build/generated-project/starter.zip
Project extracted to: /private/var/folders/lj/q3_9z0ws4ygb_bvng5vy2vs00000gn/T/spock_initSpringBootProje_0_testProjectDir13964729921630795147/build/generated-project/demo

BUILD SUCCESSFUL in 3s
1 actionable task: 1 executed
```

The tests did not pass, and I was getting the following message in the logs:

```text
Condition not satisfied:

FilesTestUtils.projectFilesExist unzipDir, 'build.gradle', 'src/main/java/com/example/demo/DemoApplication.java'
|              |                 |
|              false             /var/folders/lj/q3_9z0ws4ygb_bvng5vy2vs00000gn/T/spock_initSpringBootProje_0_testProjectDir8148397175690448479/generated-project/demo
class io.oczadly.testsupport.FilesTestUtils
```

The issue came from the fact that [Gradle TestKit](https://docs.gradle.org/9.0.0/userguide/test_kit.html) always runs the build in an isolated working directory inside `java.io.tmpdir` (e.g. `/private/var/folders/.../build/`), and not in the directory where I expected the files.

However, in the assertion (`generatedProjectDir.absolutePath`) it was looking for files in Spock’s temporary directory (`@TempDir`), which is a different location than the working directory used by [TestKit](https://docs.gradle.org/current/userguide/test_kit.html).

I solved it by:

- [x] Setting `-PoutputDir=${generatedProjectDir.absolutePath}`, which forced the plugin to save files in the place expected by the test.
{{< /admonition >}}

### Static code analysis

Every tool released for use should include a mechanism for static code analysis. In this case, the [CodeNarc plugin](https://docs.gradle.org/9.0.0/userguide/codenarc_plugin.html) was used, with a necessary set of rules useful for tools like [Gradle](https://gradle.org) plugins.

### Test coverage

As mentioned earlier, [gradle-springinitializr-plugin](https://plugins.gradle.org/plugin/io.oczadly.springinitializr) is covered by both unit and functional tests. Coverage is measured using the [JaCoCo plugin](https://docs.gradle.org/9.0.0/userguide/jacoco_plugin.html). It includes both types of tests and must exceed **80%**.

### Continuous integration

For continuous integration I used [GitHub Actions](https://github.com/features/actions). On every PR, it verifies whether the commit follows [Conventional Commits](https://www.conventionalcommits.org/en/v1.0.0/). Then it runs `gradle build`, which checks the following:

* Code compilation
* Unit and functional tests
* Static code analysis
* Test coverage

### Build Scan

At the end of the CI process, a [Build Scan](https://docs.gradle.org/9.0.0/userguide/build_scans.html) is published to https://scans.gradle.com. An example [Build Scan](https://docs.gradle.org/9.0.0/userguide/build_scans.html) from an execution can be found [here](https://scans.gradle.com/s/6tu3f64xfst2q).

### Compatibility tests

While building the plugin, it was important to ensure compatibility with multiple versions of [Gradle](https://gradle.org), as well as both [Kotlin DSL](https://docs.gradle.org/9.0.0/userguide/kotlin_dsl.html) and [Groovy DSL](https://docs.gradle.org/9.0.0/userguide/groovy_build_script_primer.html). That’s why on every PR, in addition to the previously mentioned steps, compatibility tests are run. They execute the `initSpringBootProject` task on different versions of [Gradle](https://gradle.org) using the following directories:

* `examples/simple-groovy`
* `examples/simple-kotlin`

All of this is possible thanks to the [matrix strategy in GitHub Actions](https://docs.github.com/en/actions/how-tos/write-workflows/choose-what-workflows-do/run-job-variations). More about it can be found [here](https://docs.github.com/en/actions/how-tos/write-workflows/choose-what-workflows-do/run-job-variations).

### Continuous delivery

After the CI process described above, when a commit lands in `main`, [GitHub Actions](https://github.com/features/actions) triggers a workflow that uses [semantic-release](https://semantic-release.gitbook.io/semantic-release/) to manage changes in `CHANGELOG.md`, create a new tag with a release in the repository, and publish the plugin to [Gradle - Plugins](https://plugins.gradle.org/).

---

## Summary

While building [gradle-springinitializr-plugin](https://plugins.gradle.org/plugin/io.oczadly.springinitializr), I not only enjoyed recreating `gradle init` for [Spring Boot](https://spring.io/projects/spring-boot), going through [DPE University](https://dpeuniversity.gradle.com/app/catalog) courses, exploring the [Spring Initializr](https://start.spring.io) API, [Gradle best practices](https://docs.gradle.org/9.0.0/userguide/best_practices_general.html), [Spock](https://spockframework.org/spock/docs/1.0/spock_primer.html) and [Groovy](https://groovy-lang.org/style-guide.html). I am also fully satisfied with the final result. This is not just another sample plugin. It is a tool **ready to use** locally and as part of a platform — built consciously, solidly, and following the best patterns.

For Platform Engineers it’s a ready-to-use asset for the platform, for Software Engineers – a quick start in daily work, and for explorers – a practical reference for building Gradle plugins.

{{< admonition example "What’s next?" >}}
Interested in contributing to the plugin?

👉 See how you can get involved by checking the [CONTRIBUTING](https://github.com/paweloczadly/gradle-springinitializr-plugin/blob/main/CONTRIBUTING.md) file.

Have an idea for a new feature or found a bug?

👉 Submit your idea or report an issue [here](https://github.com/paweloczadly/gradle-springinitializr-plugin/issues).
{{< /admonition >}}

{{< buymeacoffee >}}
