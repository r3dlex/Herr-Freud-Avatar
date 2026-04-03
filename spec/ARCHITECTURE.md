# Architecture — Herr Freud

## System Overview

Herr Freud is an Elixir OTP application that listens to patient diary entries
and generates therapeutic responses using a weighted memory retrieval system.

## OTP Supervision Tree

```
HerrFreud.Application
└── Supervisor (:one_for_one)
    ├── HerrFreud.Repo
    ├── HerrFreud.Style.Manager
    ├── HerrFreud.IAMQ.HttpClient
    ├── HerrFreud.IAMQ.WsClient
    ├── HerrFreud.Input.Watcher
    ├── HerrFreud.Cron.Handler
    └── Task.Supervisor (HerrFreud.Session.TaskSupervisor)
        └── Session.Processor (per session, temporary)
```

## Data Flow

### Text Session
1. File dropped into `data/input/`
2. `Input.Watcher` detects via FileSystem
3. 2-second debounce, then spawns `Session.Processor`
4. `Session.Processor` reads file, parses language tag
5. `LLM.MiniMax.translate/2` → English
6. `Memory.Retriever.fetch_for_text/1` → top 10 memories
7. `Session.Builder.build_system_prompt/4` → prompt
8. `LLM.MiniMax.chat/2` → response
9. `Memory.Distiller.distill/1` → memory strings
10. `Output.Writer.write_session/1` → file
11. `IAMQ.HttpClient.send/1` → librarian archive
12. `Memory.Store.insert_session/1` + `insert_memory/1` → SQLite

### Audio Session
Same as text, but step 4 is replaced by:
4. `STT.Client.transcribe/1` → transcript + detected_language
5. Translate if detected_language != "en"

## Key Modules

| Module | Type | Purpose |
|---|---|---|
| `HerrFreud.Application` | Application | OTP supervision tree |
| `HerrFreud.Repo` | Ecto.Repo | SQLite via ecto_sqlite3 |
| `Session.Processor` | Task | Session orchestration |
| `Memory.Retriever` | GenServer | Weighted blend retrieval |
| `LLM.MiniMax` | Module | MiniMax API calls |
| `IAMQ.HttpClient` | GenServer | HTTP polling + file fallback |
| `IAMQ.WsClient` | WebSockex | Real-time WebSocket |
| `Input.Watcher` | GenServer | FileSystem watcher |
| `Cron.Handler` | GenServer | Nudge and summary scheduling |
