defmodule HerrFreud.Memory.Retriever do
  @moduledoc """
  Retrieves memories using a weighted blend of recency and semantic similarity.

  score = (recency_weight * recency_score) + (similarity_weight * cosine_similarity)
  """
  alias HerrFreud.Repo
  alias HerrFreud.Memory.Memory

  @recency_weight Application.compile_env(:herr_freud, :herr_freud_memory_recency_weight, 0.4)
  @similarity_weight Application.compile_env(:herr_freud, :herr_freud_memory_similarity_weight, 0.6)
  @max_memories 10

  @doc """
  Fetch the top N memories for a given transcript embedding.
  """
  def fetch(transcript_embedding, max_memories \\ @max_memories)

  def fetch(transcript_embedding, max_memories) when is_binary(transcript_embedding) do
    embedding = :erlang.binary_to_term(transcript_embedding)
    fetch(embedding, max_memories)
  end

  def fetch(transcript_embedding, max_memories) when is_list(transcript_embedding) do
    memories = Repo.all(Memory)

    scored =
      Enum.map(memories, fn memory ->
        memory_embedding = :erlang.binary_to_term(memory.embedding)
        similarity = cosine_similarity(transcript_embedding, memory_embedding)
        recency = compute_recency_score(memory)
        score = (@recency_weight * recency) + (@similarity_weight * similarity)
        {memory, score}
      end)
      |> Enum.sort_by(fn {_memory, score} -> score end, :desc)
      |> Enum.take(max_memories)
      |> Enum.map(fn {memory, _score} -> memory end)

    {:ok, scored}
  end

  @doc """
  Fetch memories for a given text (will embed it first).
  """
  def fetch_for_text(text, max_memories \\ @max_memories) do
    emb_mod = embeddings_mod()
    case emb_mod.embed(text) do
      {:ok, embedding} -> fetch(embedding, max_memories)
      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  Compute cosine similarity between two vectors.
  Both vectors must be lists of floats of the same dimension.
  """
  def cosine_similarity(vec_a, vec_b) when is_list(vec_a) and is_list(vec_b) do
    dot_product(vec_a, vec_b) / (magnitude(vec_a) * magnitude(vec_b))
  end

  defp dot_product(vec_a, vec_b) do
    Enum.zip(vec_a, vec_b)
    |> Enum.reduce(0.0, fn {a, b}, acc -> a * b + acc end)
  end

  defp magnitude(vec) do
    vec
    |> Enum.reduce(0.0, fn x, acc -> x * x + acc end)
    |> :math.sqrt()
  end

  @doc """
  Compute recency score: 1.0 / (1 + days_since_session * 0.1)
  """
  def compute_recency_score(%Memory{} = memory) do
    days_since = Date.utc_today() |> Date.diff(memory.inserted_at |> DateTime.to_date())
    1.0 / (1 + days_since * 0.1)
  end

  def compute_recency_score(days_since) when is_number(days_since) do
    1.0 / (1 + days_since * 0.1)
  end

  defp embeddings_mod do
    Application.get_env(:herr_freud, :embeddings_mod, HerrFreud.Embeddings.Stub)
  end
end
