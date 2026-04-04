<p align="center">
  <img src="assets/banner.svg" alt="Herr Freud" width="600">
</p>

[![Build Status](https://img.shields.io/github/actions/workflow/status/r3dlex/openclaw-herr-freud-psychology-agent/ci.yml?style=flat-square)](https://github.com/r3dlex/openclaw-herr-freud-psychology-agent/actions)
[![Elixir Version](https://img.shields.io/badge/Elixir-1.17-blue?style=flat-square)](https://elixir-lang.org)
[![License: MIT](https://img.shields.io/badge/License-MIT-teal?style=flat-square)](#license)

# Herr Freud

Your always-available, privacy-first therapeutic journal. Herr Freud listens to what you write or say, remembers what you shared in past sessions, and responds with genuine warmth shaped in the language of depth psychology. All data stays local — nothing leaves your machine.

## Features

- **Audio and text input** — Drop a voice memo or diary note; Herr Freud handles both
- **Session memory** — Remembers history using weighted similarity search over embeddings
- **Adaptive response styles** — Focused question, open conversation, or structured intake
- **Proactive nudges** — Quietly checks in when you have been silent too long
- **Complete privacy** — All data stored in local SQLite; nothing transmitted beyond model calls
- **Obsidian archival** — Sessions archived to your vault via librarian_agent
- **Audio transcription** — faster-whisper sidecar for multi-format voice input
- **OTP-native architecture** — Rock-solid GenServers for IAMQ, input watching, cron, and style management
- **Centralized embeddings** — Uses MLX service at `EMBEDDINGS_URL` via `HerrFreud.Embeddings.Centralized`

## Skills

| Skill | Description |
|-------|-------------|
| `session_analysis` | Retrieve and analyze a therapy session transcript by session ID |

Workspace skills also available: `iamq_message_send`, `log_learning`, `improve_skill`

Skills auto-improve via post-execution hooks and nightly batch review.

## Architecture

- **Language**: Elixir/OTP
- **IAMQ ID**: none (communicates via IAMQ but has no registered agent ID)
- **Runtime**: Docker

| Module | Role |
|--------|------|
| `Input.Watcher` | FileSystem watcher for `data/input/` |
| `Session.Processor` | OTP orchestration of session flow |
| `Memory.Retriever` | Weighted blend similarity retrieval |
| `Embeddings.Centralized` | MLX embeddings via `EMBEDDINGS_URL` |
| `Style.Manager` | Loads and switches therapeutic styles |
| `STT.Client` | faster-whisper sidecar HTTP client |
| `IAMQ.WSClient` | WebSocket streaming client |

## Setup

```bash
cp .env.example .env
# Set MINIMAX_API_KEY; optionally set EMBEDDINGS_URL (default: http://host.docker.internal:18795)
docker-compose up --build
```

### Docker Volume Mounts

```yaml
- ../skills-cli:/skills-cli:ro
- ../skills:/workspace/skills:rw
- ./skills:/agent/skills:rw
```

Environment: `EMBEDDINGS_URL=http://host.docker.internal:18795`

## Development

```bash
mix deps.get && mix ecto.create && mix ecto.migrate
iex -S mix

# Tests (90% coverage target)
mix test
mix coveralls
```

Drop `.txt` or `.md` files into `data/input/` to trigger a session. Audio files are transcribed automatically via the faster-whisper sidecar.

## Related

- [openclaw-inter-agent-message-queue](https://github.com/r3dlex/openclaw-inter-agent-message-queue) — IAMQ message bus and agent registry
- [openclaw-librarian-agent](https://github.com/r3dlex/openclaw-librarian-agent) — Obsidian vault archival

## License

MIT
