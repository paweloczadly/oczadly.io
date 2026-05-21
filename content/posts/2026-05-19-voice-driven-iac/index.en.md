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
