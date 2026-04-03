# Memory System — Herr Freud

## Memory Retrieval Algorithm

Retrieves 5-10 memories using weighted blend:

```
score = (recency_weight × recency_score) + (similarity_weight × cosine_similarity)
```

Default: `recency_weight = 0.4`, `similarity_weight = 0.6`

## Recency Score

```
recency_score = 1.0 / (1 + days_since_session × 0.1)
```

- Today → 1.0
- 10 days ago → 0.5
- 100 days ago → ~0.09

## Similarity Score

Cosine similarity between:
- Current session transcript embedding
- Each stored memory embedding

```
cosine_similarity(a, b) = dot(a, b) / (|a| × |b|)
```

## Embedding Storage

- Stored as binary blob in SQLite: `:erlang.term_to_binary([float])`
- MiniMax embedding model: `embo-01`
- Cosine similarity computed in pure Elixir

## Memory Distillation

After each session, LLM extracts 1-3 memory statements:

```
System: "Extract 1-3 key memory statements from this session..."
User: <transcript>
LLM → ["Memory 1", "Memory 2"]
```

Each memory is embedded and stored with recency_score = 1.0.
