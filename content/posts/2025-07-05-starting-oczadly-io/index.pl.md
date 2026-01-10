---
title: "Start bloga oczadly.io"
subtitle: "Notes inżynierski o budowaniu platform, infrastruktury i systemów bez zbędnego szumu."
date: 2025-07-05
description: "Notes inżynierski o budowaniu platform, infrastruktury i systemów bez zbędnego szumu."
draft: false
lastmod: 2026-01-10
resources:
- name: "featured-image"
  src: "featured-image.jpg"
---

Witaj na moim blogu!

Stworzyłem go, aby dokumentować i dzielić się swoimi osobistymi doświadczeniami w budowaniu rozwiązań z zakresu architektury chmurowej, platform engineeringu oraz AI-native tooling.

Znajdziesz tu materiały, które nie są wprowadzeniami ani tutorialami, ale próbą uchwycenia sprawdzonych wzorców i decyzji w realnych, produkcyjnych kontekstach.

---

## Czego możesz się spodziewać

- Praktycznych, opartych na realnych projektach wpisów skupionych na implementacji.
- Uporządkowanych wzorców do budowania skalowalnych platform.
- Technicznych insightów dotyczących Gradle, OpenTofu, workflowów GitOps i AI-native systems.
- Czystych, minimalistycznych, pozbawionych zbędnego szumu treści.

---

## Zaczynamy

Żeby uszanować Twój czas oraz nie zostawiać Cię z samym powitaniem i zapowiedzą, co będzie na blogu, przedstawiam, jak uruchomiony jest ten blog. **W pełni automatycznie i w sposób deklaratywny**. W myśl z jednej moich ulubionych zasad:

> *"Jak coś robić, to robić to do porządku."*

1️⃣ **DNS**, który odpowiada za przekierowanie Cię do tej strony, został skonfigurowany przy użyciu [OpenTofu](https://opentofu.org/) w [tym PR](https://github.com/paweloczadly/iac/pull/7).

2️⃣ **Repozytorium bloga** zostało utworzone automatycznie w [tym PR](https://github.com/paweloczadly/iac/pull/9) z szablonu przygotowanego wcześniej [tutaj](https://github.com/paweloczadly/iac/pull/6), co pozwala mi na szybkie generowanie gotowych repozytoriów pod blogi zgodnie z moim workflow.

3️⃣ **Strona jest budowana i publikowana w procesie CI/CD** przez [Hugo](https://gohugo.io/) i [GitHub Actions](https://github.com/features/actions), zdefiniowane w [tym PR](https://github.com/paweloczadly/oczadly.io/pull/1).

Głównym motywem przewodnim całej opisanej konfiguracji było stworzenie centralnego miejsca, które łączy wszystkie elementy całości. Tym miejscem jest repozytorium [paweloczadly/iac](https://github.com/paweloczadly/iac), które jest fundamentem definiującym sposób uruchomienia bloga. Dzięki temu wszystko jest zdefiniowane w kodzie - czyli **dokładnie i porządnie**, tak jak lubię. A do tego umożliwia odtworzenie w przypadku awarii oraz daje łatość w dalszym rozwijaniu kolejnych projektów.

Dzisiaj uruchomiłem blog oczadly.io. Mój kawałek internetu, na moich zasadach.
