defmodule HerrFreud.Memory.RetrieverTest do
  use ExUnit.Case, async: false

  alias HerrFreud.Memory.Retriever
  alias HerrFreud.Memory.Memory
  alias HerrFreud.Memory.Session
  alias HerrFreud.Repo
  import Ecto.Query

  setup do
    Repo.delete_all(from m in Memory)
    Repo.delete_all(from s in Session)

    # Insert one session to satisfy the foreign-key constraint on memories.session_id.
    # All test memories reference this session; the retriever only cares about
    # the memory's own fields (embedding, inserted_at) when scoring.
    {:ok, session} =
      Repo.insert(%Session{
        id: "test-session-for-retriever-#{:rand.uniform(99_999_999)}",
        inserted_at: DateTime.utc_now() |> DateTime.truncate(:second),
        date: Date.utc_today(),
        input_mode: "text",
        source_lang: "en",
        raw_transcript: "test",
        english_transcript: "test",
        response: "test",
        style_used: "test"
      })

    {:ok, %{session_id: session.id}}
  end

  # ---------------------------------------------------------------------------
  # cosine_similarity/2
  # ---------------------------------------------------------------------------
  describe "cosine_similarity/2" do
    test "identical 2D vectors return 1.0" do
      vec = [1.0, 0.0]
      assert Retriever.cosine_similarity(vec, vec) |> Float.round(5) == 1.0
    end

    test "identical uniform vectors return 1.0" do
      vec = [1.0, 1.0]
      assert Retriever.cosine_similarity(vec, vec) |> Float.round(5) == 1.0
    end

    test "identical 4D vectors return 1.0" do
      vec = [1.0, 0.0, 0.0, 1.0]
      assert Retriever.cosine_similarity(vec, vec) |> Float.round(5) == 1.0
    end

    test "orthogonal 2D vectors return 0.0" do
      vec_a = [1.0, 0.0]
      vec_b = [0.0, 1.0]
      assert Retriever.cosine_similarity(vec_a, vec_b) |> Float.round(5) == 0.0
    end

    test "orthogonal 3D vectors return 0.0" do
      vec_a = [1.0, 0.0, 0.0]
      vec_b = [0.0, 1.0, 0.0]
      assert Retriever.cosine_similarity(vec_a, vec_b) |> Float.round(5) == 0.0
    end

    test "opposite vectors return -1.0" do
      vec_a = [1.0, 0.0, 0.0]
      vec_b = [-1.0, 0.0, 0.0]
      assert Retriever.cosine_similarity(vec_a, vec_b) |> Float.round(5) == -1.0
    end

    test "scaled colinear vectors return 1.0" do
      # [1.0, 2.0] and [2.0, 4.0] are perfectly colinear
      # dot = 2.0 + 8.0 = 10.0
      # |a| = sqrt(1 + 4) = sqrt(5)
      # |b| = sqrt(4 + 16) = sqrt(20) = 2*sqrt(5)
      # sim = 10 / (sqrt(5) * 2*sqrt(5)) = 10 / 10 = 1.0
      vec_a = [1.0, 2.0]
      vec_b = [2.0, 4.0]
      assert Retriever.cosine_similarity(vec_a, vec_b) |> Float.round(5) == 1.0
    end

    test "known 3D vectors produce expected similarity" do
      # vec_a = [1, 2, 3], vec_b = [4, 5, 6]
      # dot = 4+10+18 = 32
      # |a| = sqrt(1+4+9) = sqrt(14)
      # |b| = sqrt(16+25+36) = sqrt(77)
      # similarity = 32 / (sqrt(14) * sqrt(77))
      vec_a = [1.0, 2.0, 3.0]
      vec_b = [4.0, 5.0, 6.0]
      dot = 4.0 + 10.0 + 18.0
      mag_a = :math.sqrt(14.0)
      mag_b = :math.sqrt(77.0)
      expected = dot / (mag_a * mag_b)
      assert Retriever.cosine_similarity(vec_a, vec_b) |> Float.round(5) == Float.round(expected, 5)
    end
  end

  # ---------------------------------------------------------------------------
  # compute_recency_score/1
  # ---------------------------------------------------------------------------
  describe "compute_recency_score/1 with days_since integer" do
    test "0 days returns 1.0" do
      assert Retriever.compute_recency_score(0) |> Float.round(5) == 1.0
    end

    test "10 days returns 0.5" do
      # 1 / (1 + 10 * 0.1) = 1 / 2 = 0.5
      assert Retriever.compute_recency_score(10) |> Float.round(5) == 0.5
    end

    test "100 days returns ~0.09" do
      # 1 / (1 + 100 * 0.1) = 1 / 11 ≈ 0.0909...
      score = Retriever.compute_recency_score(100) |> Float.round(3)
      assert score == 0.091
    end

    test "negative days (future) returns above 1.0" do
      # 1 / (1 + (-5) * 0.1) = 1 / 0.5 = 2.0
      assert Retriever.compute_recency_score(-5) |> Float.round(5) == 2.0
    end
  end

  describe "compute_recency_score/1 with Memory struct" do
    test "Memory from today returns 1.0" do
      memory = %Memory{inserted_at: DateTime.utc_now() |> DateTime.truncate(:second)}
      assert Retriever.compute_recency_score(memory) |> Float.round(5) == 1.0
    end

    test "Memory from 10 days ago returns ~0.5" do
      past = DateTime.utc_now() |> DateTime.add(-10, :day) |> DateTime.truncate(:second)
      memory = %Memory{inserted_at: past}
      assert Retriever.compute_recency_score(memory) |> Float.round(5) == 0.5
    end

    test "Memory from 100 days ago returns ~0.09" do
      past = DateTime.utc_now() |> DateTime.add(-100, :day) |> DateTime.truncate(:second)
      memory = %Memory{inserted_at: past}
      score = Retriever.compute_recency_score(memory) |> Float.round(3)
      assert score == 0.091
    end
  end

  # ---------------------------------------------------------------------------
  # fetch/2
  # ---------------------------------------------------------------------------
  describe "fetch/2" do
    test "returns empty list when no memories exist", %{session_id: _sid} do
      assert {:ok, []} = Retriever.fetch([0.0, 0.0])
    end

    test "returns all memories when fewer exist than max_memories", %{session_id: sid} do
      embed_a = :erlang.term_to_binary([1.0, 0.0])
      embed_b = :erlang.term_to_binary([0.0, 1.0])
      now = DateTime.utc_now() |> DateTime.truncate(:second)

      Repo.insert!(%Memory{
        id: "mem-a-#{:rand.uniform(99_999)}",
        session_id: sid,
        content: "Memory A",
        embedding: embed_a,
        recency_score: 1.0,
        inserted_at: now
      })

      Repo.insert!(%Memory{
        id: "mem-b-#{:rand.uniform(99_999)}",
        session_id: sid,
        content: "Memory B",
        embedding: embed_b,
        recency_score: 1.0,
        inserted_at: now
      })

      assert {:ok, memories} = Retriever.fetch([1.0, 0.0])
      assert length(memories) == 2
    end

    test "returns top memories sorted by weighted score", %{session_id: sid} do
      # Insert two memories with identical recency (same inserted_at).
      # Query embedding [1, 0] should rank the [1, 0] memory higher.
      embed_a = :erlang.term_to_binary([1.0, 0.0])
      embed_b = :erlang.term_to_binary([0.0, 1.0])
      now = DateTime.utc_now() |> DateTime.truncate(:second)

      Repo.insert!(%Memory{
        id: "mem-high-sim-#{:rand.uniform(99_999)}",
        session_id: sid,
        content: "High similarity memory",
        embedding: embed_a,
        recency_score: 1.0,
        inserted_at: now
      })

      Repo.insert!(%Memory{
        id: "mem-low-sim-#{:rand.uniform(99_999)}",
        session_id: sid,
        content: "Low similarity memory",
        embedding: embed_b,
        recency_score: 1.0,
        inserted_at: now
      })

      assert {:ok, [top | _rest]} = Retriever.fetch([1.0, 0.0])
      assert top.content == "High similarity memory"
    end

    test "limits results to max_memories", %{session_id: sid} do
      embed = :erlang.term_to_binary([1.0, 0.0])
      now = DateTime.utc_now() |> DateTime.truncate(:second)

      for i <- 1..15 do
        Repo.insert!(%Memory{
          id: "mem-limit-#{i}",
          session_id: sid,
          content: "Memory #{i}",
          embedding: embed,
          recency_score: 1.0,
          inserted_at: now
        })
      end

      assert {:ok, memories} = Retriever.fetch([1.0, 0.0], 5)
      assert length(memories) == 5
    end

    test "accepts binary embedding and decodes it", %{session_id: sid} do
      embed = :erlang.term_to_binary([1.0, 0.0])
      now = DateTime.utc_now() |> DateTime.truncate(:second)

      Repo.insert!(%Memory{
        id: "mem-bin-#{:rand.uniform(99_999)}",
        session_id: sid,
        content: "Binary embedding memory",
        embedding: embed,
        recency_score: 1.0,
        inserted_at: now
      })

      binary_embed = :erlang.term_to_binary([1.0, 0.0])
      assert {:ok, [memory | _]} = Retriever.fetch(binary_embed)
      assert memory.content == "Binary embedding memory"
    end

    test "recent memories rank higher when similarity is equal", %{session_id: sid} do
      embed = :erlang.term_to_binary([1.0, 0.0])

      # Old memory: 50 days ago
      old_time = DateTime.utc_now() |> DateTime.add(-50, :day) |> DateTime.truncate(:second)
      Repo.insert!(%Memory{
        id: "mem-old-#{:rand.uniform(99_999)}",
        session_id: sid,
        content: "Old memory",
        embedding: embed,
        recency_score: 1.0,
        inserted_at: old_time
      })

      # Recent memory: today (same embedding, so same similarity)
      now = DateTime.utc_now() |> DateTime.truncate(:second)
      Repo.insert!(%Memory{
        id: "mem-recent-#{:rand.uniform(99_999)}",
        session_id: sid,
        content: "Recent memory",
        embedding: embed,
        recency_score: 1.0,
        inserted_at: now
      })

      assert {:ok, [top | _rest]} = Retriever.fetch([1.0, 0.0])
      assert top.content == "Recent memory"
    end
  end
end
