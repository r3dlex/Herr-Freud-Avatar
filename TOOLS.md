# Herr Freud — Tools and Environment Configuration (TOOLS.md)

## Development Environment

### Required Tools
- **Elixir** 1.14+
- **Erlang/OTP** 25+
- **mix** (Elixir build tool)
- **PostgreSQL** (not used — SQLite is used instead)
- **Docker** and **Docker Compose** (for production)

### Local Development
```bash
# Install dependencies
mix deps.get

# Run tests
mix test

# Run with live development
mix phx.server  # Not applicable — no Phoenix in Phase 1

# Run iex with the app
iex -S mix

# Run ecto migrations
mix ecto.migrate

# Generate a new migration
mix ecto.gen.migration add_session_notes
```

### Environment Variables

All configuration is via environment variables (see .env.example):

| Variable | Default | Required |
|---|---|---|
| MINIMAX_API_KEY | — | YES |
| MINIMAX_MODEL | abab6.5s-chat | No |
| MINIMAX_EMBEDDING_MODEL | embo-01 | No |
| IAMQ_HTTP_URL | http://127.0.0.1:18790 | No |
| IAMQ_WS_URL | ws://127.0.0.1:18793/ws | No |
| IAMQ_AGENT_ID | herr_freud_agent | No |
| IAMQ_HEARTBEAT_MS | 300000 | No |
| IAMQ_POLL_MS | 60000 | No |
| STT_SIDECAR_URL | http://stt-sidecar:9001 | No |
| STT_MODEL | large-v3 | No |
| HERR_FREUD_DB_PATH | priv/herr_freud.db | No |
| HERR_FREUD_DATA_FOLDER | ./data | No |
| HERR_FREUD_LOG_LEVEL | info | No |
| HERR_FREUD_NUDGE_AFTER_DAYS | 2 | No |
| HERR_FREUD_MEMORY_RECENCY_WEIGHT | 0.4 | No |
| HERR_FREUD_MEMORY_SIMILARITY_WEIGHT | 0.6 | No |

### Data Directory Structure
```
$HERR_FREUD_DATA_FOLDER/
├── input/              # Patient drops audio/text files here
│   ├── .retry/         # Failed STT attempts retry here
│   └── .processing/    # Currently being processed
├── sessions/           # Session transcripts written here
│   └── YYYY-MM-DD_<session_id>.md
├── nudges/             # Proactive nudge files
│   └── YYYY-MM-DD_nudge.md
└── embeddings/         # Cached embeddings (optional)
```

### External Services

#### MiniMax API
- **Purpose**: LLM chat completions and text embeddings
- **API Key**: Via MINIMAX_API_KEY env var
- **Endpoints used**:
  - Chat: https://api.minimax.chat/v1/text/chatcompletion_v2
  - Embeddings: https://api.minimax.chat/v1/embeddings

#### IAMQ Service
- **Purpose**: Inter-agent messaging and cron scheduling
- **HTTP**: Port 18790 (configurable)
- **WebSocket**: Port 18793 (configurable)
- **File fallback**: When HTTP unreachable, messages queued to $IAMQ_QUEUE_PATH

#### STT Sidecar (faster-whisper)
- **Purpose**: Speech-to-text transcription
- **URL**: http://stt-sidecar:9001
- **Endpoint**: POST /transcribe
- **Model**: large-v3 (production), base (CI/test)
