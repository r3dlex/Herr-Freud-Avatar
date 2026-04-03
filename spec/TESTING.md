# Testing Strategy — Herr Freud

## Coverage Target

90% line coverage across all `lib/herr_freud/` modules.

## Test Categories

| Module | Approach |
|---|---|
| `Memory.Retriever` | Unit tests with known vectors, cosine similarity |
| `LLM.MiniMax` | Mock HTTP via Bypass |
| `Embeddings.MiniMax` | Mock HTTP via Bypass |
| `STT.Client` | Mock HTTP via Bypass |
| `IAMQ.HttpClient` | Mock HTTP via Bypass |
| `Session.Processor` | Integration test with all stubs |
| `Output.Writer` | Tmp directory fixtures |
| `Cron.Handler` | Fake time via store injection |
| `Style.Manager` | State machine tests |

## Stub Pattern

All external calls use behaviours:

```elixir
# config/test.exs
config :herr_freud,
  llm_mod: HerrFreud.LLM.Stub,
  embeddings_mod: HerrFreud.Embeddings.Stub,
  stt_mod: HerrFreud.STT.Stub,
  iamq_http_mod: HerrFreud.IAMQ.HttpStub
```

## Running Tests

```bash
mix test                    # All tests
mix test --trace            # Verbose
mix coveralls              # Coverage
mix coveralls.html         # HTML report
```
