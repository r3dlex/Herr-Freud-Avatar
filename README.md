<p align="center">
  <img src="assets/banner.svg" alt="Herr Freud" width="600">
</p>

[![Build Status](https://img.shields.io/github/actions/workflow/status/r3dlex/openclaw-herr-freud-psychology-agent/ci.yml?style=flat-square)](https://github.com/r3dlex/openclaw-herr-freud-psychology-agent/actions)
[![Coverage](https://img.shields.io/coverallsCoverage/github/r3dlex/openclaw-herr-freud-psychology-agent?style=flat-square)](https://coveralls.io/github/r3dlex/openclaw-herr-freud-psychology-agent)
[![Elixir Version](https://img.shields.io/badge/Elixir-1.17-blue?style=flat-square)](https://elixir-lang.org)
[![License: MIT](https://img.shields.io/badge/License-MIT-teal?style=flat-square)](#license)

---

## Why Herr Freud?

Every person carries a diary in their heart. Some write it down, some speak it aloud — but almost everyone needs a private space to process their inner world, free from judgment, available at any hour.

Therapy is powerful. But scheduling a session, paying a copay, and finding the right words in 50 minutes is hard when you are in crisis at 2am, or when a feeling passes before you ever reach the couch.

**Herr Freud** is your always-available, privacy-first therapeutic journal. It listens to what you write or say, remembers what you shared in past sessions, and responds with genuine warmth — shaped in the language of depth psychology. It is not a replacement for a human analyst. It is the quiet companion in the space between sessions.

> *"The unconscious is knowable — with the right listener."*

---

## Features

| | |
|---|---|
| :microphone: | **Audio & Text Input** — Drop a voice memo or a diary note; Herr Freud handles both |
| :brain: | **Session Memory** — Remembers your history using weighted similarity search over embeddings |
| :sparkles: | **Adaptive Response Styles** — Three interaction modes: focused question, open conversation, or structured intake |
| :bell: | **Proactive Nudges** — Quietly checks in when you have been silent too long |
| :scroll: | **Style Memory** — Learns and matches your preferred therapeutic tone over time |
| :closed_lock_with_key: | **Complete Privacy** — All data stays local in SQLite. Nothing leaves your machine. |
| :floppy_disk: | **Obsidian Archival** — Sessions are archived to your vault via librarian_agent |
| :speaker_high_volume: | **Audio Transcription** — faster-whisper sidecar for multi-format voice input |
| :gear: | **OTP-Native Architecture** — Rock-solid GenServers for IAMQ, input watching, cron, and style management |
| :earth_americas: | **MiniMax LLM + Embeddings** — Thoughtful, context-grounded responses every session |

---

## Architecture

```
┌─────────────────────────────────────────────────────┐
│                   Patient Input                       │
│          (audio file  or  text file drop)            │
└──────────────────────┬──────────────────────────────┘
                       │
         ┌─────────────▼──────────────┐
         │    Input.Watcher (GenServer) │
         └─────────────┬──────────────┘
                       │ .txt / .md
         ┌─────────────▼──────────────┐
         │   Session.Processor (OTP)   │
         │   Session.Builder (prompt)  │
         └─────────────┬──────────────┘
                       │
          ┌────────────▼───────────────┐
          │   Memory.Retriever          │
          │  (weighted blend similarity) │
          └─────────────┬───────────────┘
                       │ embeddings
          ┌────────────▼───────────────┐
          │  Embeddings.MiniMax + LLM   │
          └─────────────┬───────────────┘
                       │
         ┌─────────────▼──────────────┐
         │     Style.Manager (OTP)     │
         │  matches therapeutic tone   │
         └────────────────────────────┘
                       │
         ┌─────────────▼──────────────┐
         │  Output.Writer (.md reply) │
         └────────────────────────────┘
                       │
         ┌─────────────▼──────────────┐
         │    IAMQ (HTTP + WS)         │
         │  → librarian_agent (archive)│
         └────────────────────────────┘
```

### OTP Supervisors & GenServers

| Module | Role |
|---|---|
| `IAMQ.WSClient` | WebSocket streaming client |
| `IAMQ.HTTPClient` | HTTP polling fallback |
| `Input.Watcher` | FileSystem watcher for `data/input/` |
| `Style.Manager` | Loads and switches therapeutic styles |
| `Cron.Handler` | Schedules proactive nudge delivery |
| `Memory.Store` | Ecto/SQLite CRUD for sessions and memories |
| `Memory.Retriever` | Weighted blend similarity retrieval |
| `STT.Client` | faster-whisper sidecar HTTP client |

---

## Quick Start

```bash
# 1. Clone & install
git clone https://github.com/openclaw/herr-freud-psychology-agent.git
cd herr-freud-psychology-agent
mix deps.get

# 2. Configure
cp .env.example .env
# Edit .env and add your MINIMAX_API_KEY

# 3. Set up the database
mix ecto.create
mix ecto.migrate
mix run priv/repo/seeds.exs

# 4. Launch
iex -S mix
```

---

## Docker

```bash
# Build and run all services (Herr Freud + faster-whisper STT sidecar)
docker-compose up --build

# Run services in the background
docker-compose up -d

# Run only the application container
docker-compose up -d herr-freud

# Run only the STT sidecar
docker-compose up -d stt-sidecar
```

### Environment Variables (Docker)

| Variable | Description |
|---|---|
| `MINIMAX_API_KEY` | Your MiniMax API key |
| `MINIMAX_BASE_URL` | MiniMax API base URL (optional) |
| `STT_SIDECAR_URL` | faster-whisper sidecar URL (default: `http://stt-sidecar:8000`) |
| `IAMQ_WS_URL` | WebSocket URL for librarian_agent |
| `IAMQ_HTTP_URL` | HTTP polling URL for librarian_agent |
| `LOG_LEVEL` | `info` (default), `debug`, `warning` |

---

## Usage

### Text Input

Drop a `.txt` or `.md` file into `data/input/`. Herr Freud will pick it up automatically.

```bash
echo "I had a difficult day with my brother. I kept replaying the conversation in my head." \
  > data/input/2026-04-03_diary.md
```

A response file will be written to `data/output/` when Herr Freud has finished composing.

### Audio Input

Drop any audio file into `data/input/`. The faster-whisper sidecar handles transcription.

Supported formats: `.mp3`, `.wav`, `.m4a`, `.ogg`, `.webm`

```bash
cp my_recording.wav data/input/2026-04-03_voice_entry.wav
```

### Companion Notes

If you want to add context to an entry, create a `.md` file with the same base name in the input directory. It will be attached to the session automatically.

```
data/input/2026-04-03_diary.md          ← patient entry
data/input/2026-04-03_diary-notes.md    ← companion notes
```

---

## Interaction Styles

| Style | Description |
|---|---|
| `single_question` | Herr Freud asks one focused question per session; you reflect freely until the next session |
| `conversational` | A genuine back-and-forth dialogue within the session; closes when you signal you are done |
| `structured_intake` | One question per theme each session: mood, sleep, relationships, work, body, and meaning |

Switch styles at any time by sending a message via IAMQ.

---

## Privacy

**Your data never leaves your machine.**

- All session transcripts and memories are stored in a local SQLite database (`data/herr_freud.db`)
- The MiniMax API receives only the current session transcript and retrieval context — no patient-identifying data is transmitted beyond what is strictly needed for the model call
- Archived sessions are written to your own Obsidian vault, fully under your control
- There is no telemetry, no analytics, and no third-party data sharing

For the full technical breakdown of data flows, see `ARCHITECTURE.md`.

---

## Testing

```bash
# Run all tests
mix test

# Coverage report (terminal)
mix coveralls

# Coverage report (HTML)
mix coveralls.html
open coveralls/index.html
```

All external dependencies (LLM, embeddings, STT, IAMQ, filesystem) are stubbed in `test/support/stubs.ex`. The test suite targets 90% line coverage.

---

## License

MIT License — see [LICENSE](LICENSE) for details.

---

```
╔══════════════════════════════════════════════════════╗
║  Built with Elixir/OTP  ·  Data stays local  ·  MIT  ║
╚══════════════════════════════════════════════════════╝
```
