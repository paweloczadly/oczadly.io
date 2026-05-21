---
title: "Voice-driven IaC"
subtitle: "Local pair programming for OpenTofu and GitOps."
date: 2026-05-19
description: "Local pair programming for OpenTofu and GitOps."
draft: false
resources:
- name: "featured-image"
  src: "featured-image.png"
---

<!-- Firmy coraz częściej wdrażają rozwiązania AI. Dzięki temu możliwe jest oddelegowania prostych zadań agentom, a skupienie się na tym co istotne. Jak wiemy, możliwe jest również wykorzystanie agentów do szukania źródła problemów w incydencie albo naprawianie niedziałających systemów na produkcji. Jednak wymienianie wiadomości tekstowych z agentami, tworzenie planów dla nich jest i tak czasochłonne. Ostatnio dużo mam do czynienia z tym pierwszym scenariuszem. Dzięki AI jestem bardziej produktywny. Jedyne co mogłoby się jeszcze poprawić to szybsza wymiana wiadomości z agentem. Dlatego właśnie powstał projekt na ten artykuł i towarzyszące mu rozwiązanie, które jest gotowe do użytku codziennego. -->

Okazuje się, że AI agenty są najbardziej przydatne gdy można z nimi szybko komunikować. Ja sam zauważyłem, że często przeplatam się w długich dialogach tekstowych. Czekam na odpowiedź, wpisuję pytanie, czekam znowu. To powoduje frustrację i rozproszenie. Każde polecenie to sekund wymiany zamiast naturalnego flow. Pomyślałem, że szybka, głosowa komunikacja mogłaby to zmienić. Dlatego powstał projekt na ten artykuł: agent sterowany głosem, gotowy do codziennego użytku.

## Dlaczego polecenia głosowe?

Mogłoby się wydawać, że to tylko fajny, hobbystyczny projekt na boku. Jednak zostań ze mną. Zaraz pokażę Ci realne wartości.

1. Gdy razem z agentem rozwijasz moduł OpenTofu/Terraform, Helm Charta albo tworzysz proste narzędzie w Pythonie lub Go, często oprócz najważniejszych rzeczy musisz napisać trochę mniej ambitnego kodu (np. zmienne w module OpenTofu/Terraform).
2. Gdy jesteś w trakcie debugowania albo deploymentu i zlecasz agentowi prostsze rzeczy (np. stworzenie opisu do PR'a).

W takich sytuacjach, ostatnią rzeczą jaką chcesz, to wychodzić z kontekstu na dłuższy czas. Dzięki poleceniom głosowym, wydajesz agentowi instrukcje i momentalnie wracasz do tego swoich rzeczy. Dla zespołów infrastrukturalnych, gdzie zmiana kontekstu to realny koszt, to diametralnie zmienia zasady gry.

Członek zespołu infrastrukturowego napędzany AI - słucha, myśli i działa. Uruchamiany głosem, działa głównie na laptopie.

Co robi
Przyjmuje komendy głosowe przez mikrofon
Rozumie zapytania infrastrukturalne ("zrób PR do issue #123", "czy są anomalie kosztowe?", "co się sypie w Grafanie?")
Wykonuje prawdziwe narzędzia: czyta GitHub issues, pisze Terraform / Flux YAML, uruchamia `terraform validate`, otwiera draft PR-y
Odpowiada przez głośniki
Stack
| Komponent | Wybór | Gdzie działa |
|-----------|-------|--------------|
| STT | mlx-whisper | lokalnie (Apple Silicon) |
| LLM | Claude API (wymienialny: OpenAI / Gemini) | chmura |
| TTS | Kokoro TTS | lokalnie (Apple Silicon) |
| Orkiestracja | Pipecat | lokalnie |

Tylko tekst promptu wychodzi z komputera. Audio zostaje lokalnie.
Architektura
```
mikrofon → mlx-whisper → Claude API → Kokoro TTS → głośniki
↕
narzędzia: read_issue, write_file,
terraform_validate, create_pr
```

{{< mermaid >}}
sequenceDiagram
    participant User
    participant Whisper as mlx-whisper
    participant Claude as Claude API
    participant Tools as Narzędzia
    participant TTS as Kokoro TTS
    participant Speaker as Głośniki

    User->>Whisper: nagranie audio
    Whisper->>Claude: transkrypcja
    Claude->>Tools: polecenie
    Tools->>Claude: wynik
    Claude->>TTS: odpowiedź
    TTS->>Speaker: audio
    Speaker->>User: odtworzenie
{{< /mermaid >}}

Pipecat obsługuje VAD, streaming, turn-taking i pętlę tool calls. Provider LLM wymienialny przez jedną linię konfiguracji.
Kontekst wpisu
"Głosowy członek zespołu infrastrukturowego" - praktyczny walkthrough budowania lokalnego agenta głosowego, który pisze Terraform, waliduje go i otwiera PR-y. Prawdziwy stack, prawdziwe narzędzia, prawdziwy use case.

Co czyni to interesującym
Audio w pełni lokalnie (prywatność)
Niezależny od LLM: Claude dziś, cokolwiek jutro
Narzędzia to zwykłe funkcje Pythona - żadnego lock-inu frameworka
Pipecat jako "Spring dla agentów głosowych" - hydraulika, nie logika biznesowa

```
# Voice-driven IaC.
## Local pair programming for OpenTofu and GitOps.

## The problem
[konkretny scenariusz: oncall, trzy Slack threads, dwa Grafana taby,
jeden GitHub issue - wiesz co zrobić, nie chcesz tego pisać]

## Why voice?
[redukuje friction przy status queries i triggering tasks,
nie "bo fajne"]

## Architecture
[ASCII diagram]
[tabela: komponent / wybór / gdzie działa]

## Why these components
[STT: mlx-whisper vs whisper.cpp vs Deepgram - tabela z latencją]
[TTS: Kokoro vs Piper vs ElevenLabs - tabela z jakością/latencją]
[Pipecat jako "Spring dla voice agents"]

## The tools that make it useful
[read_issue, terraform_validate, create_pr]
[validate-fix loop - kod + terminal output]

## Building it
[pipeline setup - prawdziwy kod Pipecat]
[tool registration]
[config: swap provider przez jedną linię]

## Installing and running
pip install infra-voice-agent
infra-agent start --provider anthropic
[krótkie demo: co się dzieje po uruchomieniu]

## When this doesn't make sense
[długie taski, latencja, "write 150 lines" przez głos]

## Summary
[pip install, GitHub repo link]
```

{{< buymeacoffee >}}
