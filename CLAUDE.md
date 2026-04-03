# Herr Freud — Development Conventions (CLAUDE.md)

## Module Standards

### Naming
- Modules: `CamelCase` (e.g., `SessionProcessor`)
- Functions: `snake_case` (e.g., `process_text_entry`)
- Behaviours: `HerrFreud.<ModuleName>` (e.g., `HerrFreud.LLM`)
- Structs: `snake_case` with `_struct` suffix where ambiguous

### File Structure
```
lib/herr_freud/
├── application.ex          # OTP Application
├── repo.ex                 # Ecto.Repo
├── embeddings.ex           # Behaviour (not a concrete module)
├── embeddings/
│   └── minimax.ex          # Concrete implementation
├── llm.ex                  # Behaviour
├── llm/
│   └── minimax.ex          # Concrete implementation
├── memory/
│   ├── store.ex            # CRUD
│   ├── retriever.ex        # Retrieval logic
│   └── distiller.ex        # Post-session extraction
├── session/
│   ├── processor.ex        # Orchestration
│   └── builder.ex          # Prompt construction
├── style/
│   └── manager.ex          # Style loading/switching
├── stt/
│   └── client.ex            # STT HTTP client
├── input/
│   └── watcher.ex           # FileSystem watcher
├── output/
│   └── writer.ex            # File writer
├── cron/
│   └── handler.ex           # Cron job handler
├── nudge/
│   └── generator.ex         # Nudge content generation
├── profile/
│   └── store.ex             # Patient profile CRUD
└── iamq/
    ├── http_client.ex       # HTTP polling client
    └── ws_client.ex         # WebSocket client
```

### Behaviours
All external integrations use behaviours:
```elixir
defmodule HerrFreud.LLM do
  use Behaviour

  defcallback chat(messages :: [map], opts :: keyword) :: {:ok, String.t()} | {:error, term()}
  defcallback translate(text :: String.t(), from_lang :: String.t(), to_lang :: String.t()) :: {:ok, String.t()} | {:error, term()}
end
```

### Configuration via Application Env
Never hardcode API keys or URLs. Use `Application.get_env(:herr_freud, :key)` pattern.
Test config overrides with stub implementations.

## TDD Requirements

### Test Structure
```
test/herr_freud/
├── support/
│   └── stubs.ex            # Stub implementations of behaviours
├── llm/
│   └── minimax_test.exs
├── embeddings/
│   └── minimax_test.exs
├── memory/
│   ├── store_test.exs
│   ├── retriever_test.exs
│   └── distiller_test.exs
├── session/
│   ├── processor_test.exs
│   └── builder_test.exs
├── style/
│   └── manager_test.exs
├── stt/
│   └── client_test.exs
├── input/
│   └── watcher_test.exs
├── output/
│   └── writer_test.exs
├── cron/
│   └── handler_test.exs
├── nudge/
│   └── generator_test.exs
├── profile/
│   └── store_test.exs
└── iamq/
    ├── http_client_test.exs
    └── ws_client_test.exs
```

### Test Coverage
- Target: 90% line coverage
- Command: `mix coveralls`
- Stub everything external: LLM calls, embeddings, STT, IAMQ, filesystem

### Stub Implementations
```elixir
defmodule HerrFreud.LLM.Stub do
  @behaviour HerrFreud.LLM

  def chat(_messages, _opts), do: {:ok, "Stubbed response"}
  def translate(text, _from, _to), do: {:ok, text}
end
```

## OTP Guidelines

### GenServers
- Always implement `start_link/1` with `:gen_server.start_link(__MODULE__, args, opts)`
- Use `handle_info(:timeout, state)` for delayed work
- Return `{:noreply, state}` or `{:stop, reason, state}`
- Use `Process.send_after(self(), :work, delay_ms)` for debouncing

### Supervisors
- One-for-one strategy for independent workers
- Simple one-for-one for task supervisors
- Always tag session processors as temporary so they auto-restart on crash

### Tasks
- Use `Task.start(fn -> ... end)` for fire-and-forget
- Use `Task.Supervisor` for session processors
- Return `{:noreply, state, :hibernate}` for long-running tasks

## Error Handling

### Happy path: `with` constructs
```elixir
with {:ok, transcript} <- STT.Client.transcribe(file_path),
     {:ok, english} <- LLM.translate(transcript, lang, "en"),
     {:ok, memories} <- Memory.Retriever.fetch(embedding) do
  # ...
end
```

### External API errors
```elixir
defp api_error(reason) do
  Logger.error("External API error: #{inspect(reason)}")
  {:error, reason}
end
```

## Logging

- Use `Logger.info/1`, `Logger.warning/1`, `Logger.error/1`
- Always include struct field names in error logs: `Logger.error("STT failed: #{inspect(reason)}, file: #{file_path}")`
- Never log patient transcript content — only session ID and timing
