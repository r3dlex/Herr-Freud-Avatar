# ADR-002: Dual IAMQ Transport

**Status:** Proposed

**Date:** 2026-04-03

## Context

The agent must send and receive IAMQ messages reliably within a local network environment where the IAMQ service may be temporarily unavailable. A single transport mechanism (e.g., HTTP-only polling) introduces latency on the receive path and creates a blind spot when the HTTP endpoint is down. At the same time, relying exclusively on a persistent WebSocket connection risks silent message loss during brief network glitches or service restarts.

## Decision

The system runs two concurrent IAMQ transport clients under a shared OTP supervision strategy:

1. **HTTP Polling Client** (`HerrFreud.IAMQ.HTTPClient`) — primary transport
2. **WebSocket Client** (`HerrFreud.IAMQ.WSClient`) — realtime transport

### HTTP Polling Client

- Polls the IAMQ HTTP endpoint every **60 seconds**.
- On poll failure, messages are enqueued to a local JSONL file (`priv/iamq_queue.jsonl`) as a durable fallback.
- On recovery, the queued messages are flushed to IAMQ before resuming normal polling.
- Tracks message acknowledgement via HTTP response status.

### WebSocket Client

- Maintains a persistent WebSocket connection to the IAMQ realtime endpoint.
- Sends a heartbeat (ping/pong frame) every **300 seconds** to detect stale connections.
- On unexpected disconnect, the client enters exponential backoff reconnection (max 5 attempts, starting at 1 second).
- Receives inbound messages asynchronously and dispatches them to the session processor.

### Supervision Tree

```
HerrFreud.Application
└── IAMQ.Supervisor (one_for_one)
    ├── IAMQ.HTTPClient  (transient — restarted on normal exit)
    └── IAMQ.WSClient    (transient)
```

Both clients are registered as transient workers so that a deliberate stop does not trigger restart loops.

### Message Deduplication

Since both transports may deliver the same message, the session processor maintains an in-memory `MapSet` of recently seen message IDs (TTL: 5 minutes) to suppress duplicates. The dedupe window is configurable via `HERR_FREUD_IAMQ_DEDUPE_TTL_SECONDS`.

## Consequences

**Positive:**
- Graceful degradation: HTTP fallback queue ensures no message loss during brief service outages.
- Low-latency receive path via WebSocket eliminates 60-second polling lag for inbound messages.
- Independent transports allow incremental rollout and isolated failure diagnosis.

**Negative:**
- Two clients to implement, test, and maintain.
- Potential for duplicate message delivery despite the dedupe layer; the in-memory dedupe does not survive node restarts.
- WebSocket reconnection logic adds complexity; exponential backoff must be carefully tuned to avoid hammering a recovering service.
- Both transports must share the same authentication credentials, increasing the blast radius of a credential compromise.

**Neutral:**
- The 60s / 300s intervals are conservative defaults; they should be benchmarked against the actual network path latency before tuning.
- Local JSONL queue file grows unboundedly in a prolonged outage — future work should add a maximum queue size or TTL eviction policy.