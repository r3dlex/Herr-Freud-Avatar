defmodule HerrFreud.Memory.Store do
  @moduledoc """
  CRUD operations for sessions and memories.
  """
  alias HerrFreud.Memory.{Memory, Session}
  alias HerrFreud.Repo
  import Ecto.Query

  @doc """
  Insert a new session.
  """
  def insert_session(attrs) do
    session = %Session{
      id: Map.get(attrs, :id) || Ecto.UUID.generate(),
      inserted_at: DateTime.utc_now() |> DateTime.truncate(:second),
      date: Map.get(attrs, :date) || Date.utc_today(),
      input_mode: Map.get(attrs, :input_mode),
      source_lang: Map.get(attrs, :source_lang),
      raw_transcript: Map.get(attrs, :raw_transcript),
      english_transcript: Map.get(attrs, :english_transcript),
      response: Map.get(attrs, :response),
      style_used: Map.get(attrs, :style_used),
      embedding: Map.get(attrs, :embedding)
    }

    Repo.insert(session)
  end

  @doc """
  Get a session by ID.
  """
  def get_session(id) do
    Repo.get(Session, id)
  end

  @doc """
  List all sessions, ordered by most recent first.
  """
  def list_sessions do
    Session
    |> order_by(desc: :inserted_at)
    |> Repo.all()
  end

  @doc """
  List sessions since a given date.
  """
  def list_sessions_since(date) when is_binary(date) do
    date = Date.from_iso8601!(date)
    list_sessions_since(date)
  end

  def list_sessions_since(date) do
    Session
    |> where([s], s.date >= ^date)
    |> order_by(desc: :inserted_at)
    |> Repo.all()
  end

  @doc """
  Get the most recent session.
  """
  def get_most_recent_session do
    Session
    |> order_by(desc: :inserted_at)
    |> first()
    |> Repo.one()
  end

  @doc """
  Insert a new memory.
  """
  def insert_memory(attrs) do
    memory = %Memory{
      id: Map.get(attrs, :id) || Ecto.UUID.generate(),
      session_id: Map.get(attrs, :session_id),
      content: Map.get(attrs, :content),
      embedding: Map.get(attrs, :embedding),
      recency_score: Map.get(attrs, :recency_score) || 1.0,
      inserted_at: Map.get(attrs, :inserted_at) |> then(fn
        nil -> DateTime.utc_now() |> DateTime.truncate(:second)
        dt -> DateTime.truncate(dt, :second)
      end)
    }

    Repo.insert(memory)
  end

  @doc """
  Get all memories for a given session.
  """
  def get_memories_for_session(session_id) do
    Memory
    |> where([m], m.session_id == ^session_id)
    |> Repo.all()
  end

  @doc """
  Get all memories.
  """
  def list_memories do
    Repo.all(Memory)
  end

  @doc """
  Delete memories older than a given date.
  """
  def delete_memories_older_than(date) when is_binary(date) do
    date = Date.from_iso8601!(date)
    delete_memories_older_than(date)
  end

  def delete_memories_older_than(date) do
    cutoff = DateTime.new!(date, ~T[00:00:00])
    Memory
    |> where([m], m.inserted_at < ^cutoff)
    |> Repo.delete_all()
  end

  @doc """
  Update recency score for a memory.
  """
  def update_recency_score(id, score) do
    Repo.get(Memory, id)
    |> Ecto.Changeset.change(%{recency_score: score})
    |> Repo.update()
  end
end
