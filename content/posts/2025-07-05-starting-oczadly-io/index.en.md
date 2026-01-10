---
title: "Starting oczadly.io"
subtitle: "Engineering notes on building, platforms, infrastructure, and systems that scales responsibly."
date: 2025-07-05
description: "Engineering notes on building, platforms, infrastructure, and systems that scales responsibly."
draft: false
lastmod: 2026-01-10
resources:
- name: "featured-image"
  src: "featured-image.jpg"
---

Welcome to my blog!

I've built it to document and share my personal experiences in building solutions for cloud architecture, platform engineering, and AI-native tooling.

You won't find beginner tutorials here. This blog focuses on documenting real-world decisions, trade-offs and patterns that emerge in production systems.

---

## What to expect

- Practical, implementation-focused posts grounded in real projects.
- Structured patterns for building and evolving platform architectures.
- Technical insights on Gradle, OpenTofu, GitOps workflows, and AI-native systems.
- Clean, minimal, and deliberately noise-free.

---

## Let’s get started

To respect your time and avoid leaving you with just a welcome and a list of future topics, I want to share how this blog is set up: **fully automated and declaratively managed**. Following one of my favourite principles:

> *"If something is worth doing, it’s worth doing well."*

1️⃣ **DNS** routing to this site is configured using [OpenTofu](https://opentofu.org/), as shown in [this PR](https://github.com/paweloczadly/iac/pull/7).

2️⃣ The **repository for this blog** was created automatically in [this PR](https://github.com/paweloczadly/iac/pull/9) from a pre-defined template prepared in [this PR](https://github.com/paweloczadly/iac/pull/6), allowing me to quickly generate ready-to-use repositories aligned with my workflow.

3️⃣ The **site is built and published through a CI/CD process** using [Hugo](https://gohugo.io/) and [GitHub Actions](https://github.com/features/actions), as defined in [this PR](https://github.com/paweloczadly/oczadly.io/pull/1).

The main idea behind this setup was to **create a single place that connects all parts of the system**. This place is the [paweloczadly/iac](https://github.com/paweloczadly/iac) repository, which defines how the blog is deployed, ensuring that everything is defined in code - **done thoroughly and properly**, just the way I like it. It also makes it easy to recover in case of failure and provides a clean foundation for evolving and extending future projects.

Today I launched oczadly.io. My corner of the internet, on my terms.
