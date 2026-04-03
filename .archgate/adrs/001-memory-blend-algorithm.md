# ADR-001: Memory Retrieval Algorithm

**Status:** Proposed

**Date:** 2026-04-03

## Context

Each therapeutic session must retrieve the most relevant prior memories to provide contextual continuity for the agent's responses. The retrieval must balance two signals: how recently a memory was encoded (recency) and how semantically similar it is to the current session's content (cosine similarity). Neither signal alone is sufficient — a recent but irrelevant memory is less useful than a slightly older but highly relevant one.

## Decision

Memory retrieval uses a weighted blend score computed as:

```
score = (W_recency * recency_score) + (W_similarity * cosine_similarity)
```

### Recency Score (exponential decay)

```
recency_score = 1.0 / (1.0 + days_since * 0.1)
```

- `days_since = 0`  → score = 1.0 (today)
- `days_since = 10` → score ≈ 0.50
- `days_since = 30` → score ≈ 0.25
- `days_since = 90` → score ≈ 0.10

### Cosine Similarity

Cosine similarity is computed in pure Elixir using `Nx` (or a lightweight float-list implementation if `Nx` is unavailable) against the session's current embedding vector. All memories are pre-encoded with the same embedding model at write time.

### Configurable Weights

Default weights can be overridden via environment variables:

| Environment Variable | Default | Purpose |
|---|---|---|
| `HERR_FREUD_MEMORY_RECENCY_WEIGHT` | `0.4` | Weight for recency signal |
| `HERR_FREUD_MEMORY_SIMILARITY_WEIGHT` | `0.6` | Weight for cosine similarity signal |

Weights are read at application startup and cached in the `Memory.Retriever` module state. Changing weights requires a restart.

### Result Set

- Maximum 10 memories returned per retrieval.
- Sorted by `score` descending.
- If fewer than 10 candidates exist, all candidates are returned.

## Consequences

**Positive:**
- Provides a principled, tunable balance between freshness and relevance.
- Pure Elixir computation — no external service calls at retrieval time.
- Weighted blending is easy to reason about and tune based on patient outcomes.

**Negative:**
- Requires pre-computed embedding vectors for every memory and every session transcript.
- If embedding quality degrades, retrieval quality degrades with no runtime signal.
- Config changes require application restart; no hot-reload of weights.
- Recency decay rate (factor 0.1) is currently hard-coded; future work could externalize it.

**Neutral:**
- The 0.4 / 0.6 default split was chosen heuristically; it should be treated as a starting point and evaluated against retrieval precision metrics once patient data is available.