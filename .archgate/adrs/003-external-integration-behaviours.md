# ADR-003: External Integration via Behaviours

**Status:** Proposed

**Date:** 2026-04-03

## Context

The system integrates with several external services — MiniMax LLM (chat completions, embeddings), the faster-whisper STT sidecar, and the IAMQ transport — all of which must be testable without hitting live APIs or spinning up real sidecar processes. Direct module calls to these external services in business logic would make unit testing brittle and CI unreliable.

## Decision

All external integrations are abstracted behind **Elixir behaviours** (interfaces). Each behaviour defines a fixed set of callbacks; production implementations call the real service, and test implementations are lightweight stubs.

### Behaviours

| Behaviour | Callbacks | Production Module |
|---|---|---|
| `HerrFreud.LLM` | `chat/2`, `translate/3` | `HerrFreud.LLM.MiniMax` |
| `HerrFreud.Embeddings` | `embed/1`, `embed_batch/1` | `HerrFreud.Embeddings.MiniMax` |
| `HerrFreud.STT` | `transcribe/1` | `HerrFreud.STT.Client` (HTTP) |
| `HerrFreud.IAMQ.HTTP` | `poll/1`, `send/2` | `HerrFreud.IAMQ.HTTPClient` |
| `HerrFreud.IAMQ.WS` | `connect/1`, `send/2`, `disconnect/0` | `HerrFreud.IAMQ.WSClient` |

### Dependency Injection via Application Env

Module selection is deferred to application environment:

```elixir
config :herr_freud,
  llm_mod: HerrFreud.LLM.MiniMax,
  embeddings_mod: HerrFreud.Embeddings.MiniMax,
  stt_mod: HerrFreud.STT.Client,
  iamq_http_mod: HerrFreud.IAMQ.HTTPClient
```

At startup, `HerrFreud` modules fetch the configured module via `Application.get_env(:herr_freud, :llm_mod)` and call it through the behaviour's public API. No module directly `use`s or `alias`es a concrete implementation.

### Stub Implementations for Tests

Each behaviour ships a stub implementation in `test/herr_freud/support/stubs.ex`:

```elixir
defmodule HerrFreud.LLM.Stub do
  @behaviour HerrFreud.LLM
  def chat(_messages, _opts), do: {:ok, "stubbed response"}
  def translate(text, _from, _to), do: {:ok, text}
end
```

Tests override the application env to point at the stub:

```elixir
Application.put_env(:herr_freud, :llm_mod, HerrFreud.LLM.Stub)
```

## Consequences

**Positive:**
- Business logic is fully testable without network access, API keys, or sidecar processes.
- Behaviour contracts serve as living documentation for the expected interface.
- Swapping implementations (e.g., swapping MiniMax for a different LLM provider) requires only a configuration change.
- Stubs can be composed with `ExUnit` callbacks to simulate error conditions, latency, and malformed responses.

**Negative:**
- Every integration call incurs an indirection: business logic → behaviour API → implementation module.
- Behaviour callbacks must be kept in sync with production API surface; drift can cause runtime errors if the behaviour is updated but implementations lag.
- Test configuration via `Application.put_env` can leave state bleeding between tests if `setup`/`teardown` is not disciplined — use `Application.put_env(...), on_exit: fn -> ... end` in test callbacks.

**Neutral:**
- The pattern adds roughly one file per integration (the behaviour definition), which is a minor upfront cost for significant long-term testability.
- Developers integrating a new external service must implement the behaviour's callbacks — this enforces consistency but may feel ceremonial for trivial integrations.