---
title: "gradle init for Spring Boot"
subtitle: "Production-ready Gradle plugin inspired by DPE University courses."
date: 2025-07-11
description: "Production-ready Gradle plugin inspired by DPE University courses."
draft: false
resources:
- name: "featured-image"
  src: "featured-image.png"
- name: "install.sh"
  src: install.sh
---

## Why yet another Gradle Plugin

Recently, I wanted to deepen my understanding of Build Scans, Develocity, and their practical applications, so I started going through the courses on our DPE University platform. In my daily work, I interact with Develocity from the operational and production side — maintaining open-source instances among other things — so I wanted to better understand the product, especially from the end-user perspective, to support my daily engineering work.

To systematize what I was learning, I decided to build a project that aligns with the best practices discussed in these courses. At the same time, I was working on a Spring Boot microservice generated via Spring Initializr and noticed there was no Gradle plugin that would automate this process in a way that is build cache-friendly and CI/CD-friendly.

That’s how the **`gradle-springinitializr-plugin`** was born—a production-ready tool that simplifies bootstrapping Spring Boot projects directly from Gradle. This post covers how it was built, how it works, and how you can use it to speed up starting new projects within your team.

{{< admonition example "Quick start" >}}
The plugin is open-source and available on the Gradle Plugin Portal—you can install and start using it right away.
Add it globally in your `~/.gradle/init.d`:

```shell
curl -fsSL https://oczadly.io/2025-07-11-making-gradle-plugins-production-ready/install.sh | bash
```

This way, you can generate new Spring Boot projects with Gradle while reading this post, accelerating your onboarding and daily work.

👉 [GitHub](#)

👉 [Gradle Plugin Portal](#)

If you ever want to remove the plugin, simply delete the `~/.gradle/init.d/spring-initializr.gradle` file.
{{< /admonition >}}

Along the way, I also wanted to create a **reference, production-grade Groovy plugin** that follows Gradle best practices and is backed by a full CI/CD pipeline, so I have a clean template ready for future plugins I plan to build.

---

## Who is this plugin for

**Platform Engineers**

[`gradle-springinitializr-plugin`](#) can become a part of your platform to accelerate microservice scaffolding across your organization. With it, you can:

✅ Quickly generate Spring Boot microservices (Groovy/Java/Kotlin, Gradle/Maven) from CLI, pipelines, or automated GitOps processes.

✅ Always generate projects with the latest Spring Boot, Java, and dependency versions, eliminating the need to manually maintain templates.

✅ Provide a build cache-aware, CI-friendly workflow from day one of your projects.

✅ Standardize project structure, metadata (groupId, artifactId, packageName, description), and the microservice creation process.

If you are building an engineering platform for JVM-based developer teams, this plugin can become a lightweight, configurable, and automatable pipeline element for “just-in-time” scaffolding of Spring Boot projects.

**Software Engineers**

[`gradle-springinitializr-plugin`](#) can become your go-to tool for quickly starting Spring Boot projects without leaving the Gradle ecosystem.
Instead of clicking through the Spring Initializr web UI or writing curl commands, you can generate a fully customizable project with a single Gradle command.
It saves time, ensures consistent configurations, and integrates immediately into your build cache, CI/CD, and team conventions.

**The Curious and Mindful**

[`gradle-springinitializr-plugin`](#) lets you see how Spring Boot project generation from Gradle works in under a minute, without clicking around start.spring.io or writing curl commands. Instead of manually downloading ZIP files, you can instantly start a project locally and explore Spring Boot in a repeatable, clean, and user-friendly way.

---

## How it works

After installing the gradle-springinitializr-plugin, you can generate Spring Boot projects directly from Gradle without leaving your terminal.

The plugin exposes a single task, initSpringBootProject, which fetches a project from Spring Initializr. Instead of clicking through the web UI, you can simply run:

```shell
gradle initSpringBootProject
```

You will get:

```
> Task :initSpringBootProject
Downloading Spring Boot starter project...
Project downloaded to: /Users/pawel/build/generated-project/starter.zip

BUILD SUCCESSFUL in 1s
```

By default, the project will be downloaded and unpacked into build/generated-project/, ready to open and run.

The plugin also allows you to set any parameter available in Spring Initializr:

```shell
gradle initSpringBootProject \
    -PprojectType=gradle-project-kotlin \
    -Planguage=kotlin \
    -PbootVersion=4.0.0-SNAPSHOT \
    -PoutputDir=my-spring-app \
    -PartifactId=my-spring-app \
    -PprojectName="My Spring App" \
    -PprojectDescription="My Spring Boot application generated via gradle-springinitializr-plugin" \
    -PpackageName=com.mycompany.myspringapp \
    -Ppackaging="war" \
    -PjavaVersion="21" \
    -PgroupId=com.mycompany
```

This enables you to generate clean, consistent projects, ready for your team’s CI/CD workflows and conventions, without manual steps.

---

## How it’s built

As I mentioned earlier, besides applying what I learned from DPE University courses, I wanted this plugin to serve as a **reference implementation** for building future plugins. My goal was to create something solid, timeless, and nearly maintenance-free.

### `plugin.properties`

At the heart of the plugin is the `plugin.properties` file, which contains default parameter values and fallbacks (in case the metadata API is unavailable). This design ensures that if I need to update supported Spring Boot versions or project types in the future, I won’t need to modify the code — updating the properties file will be enough.

### URL and Metadata Endpoint

The Spring Initializr URL and the endpoint for fetching supported Spring Boot versions, project types and languages are designed as **plugin-wide configuration** - you can treat them as global settings. They don't apply to a specific `initSpringBootProject` task invocation. Instead, they define **where** the data comes from, not **what** should be in the project.

More on how supported options are fetched - in the next section.

The plugin applies default values for the Spring Initializr URL and metadata endpoint by using Gradle’s [`convention(...)`](https://docs.gradle.org/current/userguide/lazy_configuration.html#applying_conventions) mechanism. This allows setting sensible defaults while still letting the user override them when needed. As a result, builds stay clean and predictable - with flexibility when you want it.

If you try to override initializrUrl using `-PinitializrUrl=https://your-initializr.example.com`, the plugin will still fall back to the default https://start.spring.io. That’s because this value is treated as plugin-level configuration, not a task input.

You can easily override it in your `build.gradle`:

```groovy
plugins {
    id 'io.oczadly.springinitializr' version '1.3.0'
}

task initSpringBootProject {
    initializrUrl = 'https://your-initializr.example.com'
    metadataEndpoint = '/yours'
}
```

See the official [Gradle documentation on `convention(...)`](https://docs.gradle.org/8.14.3/userguide/lazy_configuration.html#applying_conventions) to learn how to set clean, overridable defaults in your own plugins and tasks.

### Fetching supported options from the Metadata API

As mentioned earlier, the plugin fetches the supported Spring Boot versions, project types, and programming languages directly from the Spring Initializr [Metadata endpoint](https://docs.spring.io/initializr/docs/current/reference/html/#metadata-format). Thanks to that, there's no need to constantly update the plugin with the latest valid options.

While adding support for validating project types and languages, I ran into an interesting issue with Gradle's [configuration cache](https://docs.gradle.org/8.14.2/userguide/configuration_cache.html). More below.

{{< admonition success "Lessons learned from the --configuration-cache" >}}
Initially, I encountered several issues when testing the plugin with `--configuration-cache`. At first, I assumed the problem was related to reading my `plugin.properties`, but the actual cause was accessing `project.*` APIs inside the `@TaskAction` method:

```groovy
package io.oczadly.tasks

abstract class InitSpringBootProjectTask extends DefaultTask {

  @Internal
  final ListProperty<String> supportedProjectTypes = project.objects.listProperty String

  @Internal
  final ListProperty<String> supportedLanguages = project.objects.listProperty String

  /* Remaining code omitted */
}
```

This breaks configuration caching because Gradle requires all inputs to be declared explicitly using `Property<T>`, `Provider<T>`, or `DirectoryProperty`. Any access to mutable project state during the execution phase is disallowed.

I solved this by:

- [x] Moving all configuration logic to the `apply()` phase.

- [x] Using `project.providers.gradleProperty(...)` to connect user input via Providers.

- [x] Setting defaults with `set(...)` and `convention(...)`.

- [x] And ensuring the task action only uses strongly typed, lazily evaluated properties.

This change not only made the plugin compatible with configuration cache, but also led to a cleaner, more idiomatic Gradle implementation overall.

See the official [Gradle documentation on configuration cache](https://docs.gradle.org/8.14.2/userguide/configuration_cache.html) for full details and constraints.
{{< /admonition >}}

### `-P` parameters and validation mechanism

The plugin accepts all parameters available on https://start.spring.io - the same ones you would configure via the Spring Initializr web UI.

* `projectType`: corresponds to the Project field in Spring Initializr. Default: **Gradle**.
* `language`: corresponds to the Language field. Default: **Java**.
* `bootVersion`: corresponds to the Spring Boot version field. Default: **3.5.3**.
* `groupId`: corresponds to the Group field under Project Metadata. Default: **com.example**.
* `artifactId`: corresponds to the Artifact field. Default: **demo**.
* `projectName`: corresponds to the Name field. Default: **demo**.
* `projectDescription`: corresponds to the Description field. Default: **Demo project for Spring Boot**.
* `packageName`: corresponds to the Package name field. Default: **com.example.demo**.
* `packaging`: corresponds to the Packaging option. Default: **jar**.
* `javaVersion`: corresponds to the Java version dropdown. Default: **17**.

When no parameters are passed to the task — for example:

```shell
gradle initSpringBootProject
```

The plugin uses default values declared in the `plugin.properties` file:

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

Once all parameters have been passed or resolved to defaults, the plugin performs validation. It first queries the metadata endpoint to fetch the list of supported Spring Boot versions, project types, and languages. If the API is unavailable, it falls back to values defined in `plugin.properties`:

```properties
task.initSpringBootProject.property.projectType.fallback=gradle-project,gradle-project-kotlin,maven-project
task.initSpringBootProject.property.language.fallback=groovy,kotlin,java
task.initSpringBootProject.property.bootVersion.fallback=4.0.0-SNAPSHOT,3.5.4-SNAPSHOT,3.5.3,3.4.8-SNAPSHOT,3.4.7
task.initSpringBootProject.property.packaging.fallback=jar,war
task.initSpringBootProject.property.javaVersion.fallback=24,21,17
```

If a user passes an invalid value - one that’s not supported - the task will fail fast with an explicit error message. For example:

```shell
gradle initSpringBootProject -Planguage=clojure

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

### Incremental build and Build Cache

Based on the [Gradle Build Caching](https://dpeuniversity.gradle.com/app/learning_paths/b82f8dd7-d61e-450f-820e-3e719ef70bee) path at DPE University and the lessons learned there, the plugin supports both [incremental build](https://docs.gradle.org/8.14.3/userguide/incremental_build.html) and the [Build Cache](https://docs.gradle.org/8.14.3/userguide/build_cache.html). This allows subsequent runs to be near-instant while reusing previous results.

The `initSpringBootProject` task declares `outputDir` as an `@OutputDirectory` backed by a `DirectoryProperty`. This gives Gradle full control over tracking the output directory state, enabling:

* Incremental build support with results skipped (`UP-TO-DATE`) when nothing has changed.
* Build Cache support with task outputs restored (`FROM-CACHE`) if the original files have been deleted.

Below is a demonstration of how the task behaves in both scenarios.

#### Incremental build

On the first run, the Spring Boot project is downloaded from Spring Initializr:

```shell
gradle initSpringBootProject -PoutputDir=/Users/paweloczadly/my-spring-boot-app --console=plain --info

...

:initSpringBootProject (Thread[#67,Execution worker Thread 2,5,main]) started.

> Task :initSpringBootProject
Build cache key for task ':initSpringBootProject' is 994f91705bf7acb0c7fc0cc899de7b9a
Task ':initSpringBootProject' is not up-to-date because:
  No history is available.
Downloading Spring Boot starter project...
Project downloaded to: /Users/paweloczadly/my-spring-boot-app/starter.zip
Stored cache entry for task ':initSpringBootProject' with cache key 994f91705bf7acb0c7fc0cc899de7b9a

BUILD SUCCESSFUL in 15s
5 actionable tasks: 1 executed, 4 up-to-date
```

On subsequent runs with the same `-PoutputDir` parameter:

```shell
gradle initSpringBootProject -PoutputDir=/Users/paweloczadly/my-spring-boot-app --console=plain --info

...

> Task :initSpringBootProject UP-TO-DATE
Build cache key for task ':initSpringBootProject' is 994f91705bf7acb0c7fc0cc899de7b9a
Skipping task ':initSpringBootProject' as it is up-to-date.

BUILD SUCCESSFUL in 438ms
1 actionable task: 1 up-to-date
```

The task is skipped thanks to incremental build, as indicated by `UP-TO-DATE`.

#### Build Cache

If the file `/Users/paweloczadly/my-spring-boot-app/starter.zip` is deleted and the task is executed again:

```shell
gradle initSpringBootProject -PoutputDir=/Users/paweloczadly/my-spring-boot-app --console=plain --info

...

:initSpringBootProject (Thread[#102,Execution worker Thread 5,5,main]) started.

> Task :initSpringBootProject FROM-CACHE
Build cache key for task ':initSpringBootProject' is 994f91705bf7acb0c7fc0cc899de7b9a
Task ':initSpringBootProject' is not up-to-date because:
  Output property 'outputDir' file /Users/paweloczadly/my-spring-boot-app has been removed.
  Output property 'outputDir' file /Users/paweloczadly/my-spring-boot-app/starter.zip has been removed.
Loaded cache entry for task ':initSpringBootProject' with cache key 994f91705bf7acb0c7fc0cc899de7b9a

BUILD SUCCESSFUL in 498ms
5 actionable tasks: 1 from cache, 4 up-to-date
```

This time, the task uses the local build cache, as indicated by `FROM-CACHE`.

{{< admonition success "Insights from the Gradle Build Cache path (DPE University)" >}}
While completing the [Gradle Build Caching](https://dpeuniversity.gradle.com/app/learning_paths/b82f8dd7-d61e-450f-820e-3e719ef70bee) path on DPE University, I became curious about how the local build cache works and what exactly gets stored inside it. So I decided to take a closer look.

After executing the `initSpringBootProject` task, the cache key `994f91705bf7acb0c7fc0cc899de7b9`a appears. It’s a compressed archive located in `$GRADLE_HOME/caches/build-cache-1`. Once unpacked, you’ll find the `METADATA` file with the following details:

```properties
#Generated origin information
#Sun Jul 13 13:47:46 CEST 2025
buildCacheKey=994f91705bf7acb0c7fc0cc899de7b9a
buildInvocationId=unvev47z5bbdnodiwbt2zneg6q
creationTime=1752407266256
executionTime=798
gradleVersion=8.14.1
identity=\:initSpringBootProject
type=org.gradle.api.internal.tasks.execution.TaskExecution
```

Inside the `tree-outputDir/` directory, you’ll find the archived `starter.zip` file - the exact output previously downloaded from Spring Initializr.
{{< /admonition >}}

If you’d like to dive deeper, check out the official Gradle docs:

👉 [Incremental build](https://docs.gradle.org/8.14.3/userguide/incremental_build.html).

👉 [Build Cache](https://docs.gradle.org/8.14.3/userguide/build_cache.html).

### Interactive mode

<!-- TODO -->

## Production-readiness

<!-- TODO -->

### Unit tests

<!-- TODO -->

### Functional tests

<!-- TODO -->

### Code coverage

<!-- TODO -->

### Static code analysis

<!-- TODO -->

### Compatibility tests

<!-- TODO -->

### CI + CD

<!-- TODO -->

## Summary

<!-- TODO -->

### CTA

<!-- TODO -->
