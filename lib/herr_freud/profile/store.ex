defmodule HerrFreud.Profile.Store do
  @moduledoc """
  Patient profile CRUD operations.
  """
  alias HerrFreud.Repo

  defmodule Entry do
    @moduledoc false
    defstruct key: nil, value: nil, updated_at: nil
  end

  @doc """
  Get a profile entry by key.
  """
  def get(key) do
    case Repo.query("SELECT key, value, updated_at FROM patient_profile WHERE key = ?", [key]) do
      {:ok, %{rows: [[key, value, updated_at]]}} ->
        {:ok, %{key: key, value: value, updated_at: updated_at}}

      {:ok, %{rows: []}} ->
        {:error, :not_found}

      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc """
  Get all profile entries.
  """
  def get_all do
    case Repo.query("SELECT key, value, updated_at FROM patient_profile ORDER BY key") do
      {:ok, %{rows: rows}} ->
        entries =
          Enum.map(rows, fn [key, value, updated_at] ->
            %{key: key, value: value, updated_at: updated_at}
          end)

        {:ok, entries}

      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc """
  Put a profile entry (insert or update).
  """
  def put(key, value) when is_binary(value) do
    now = DateTime.utc_now() |> DateTime.to_iso8601()

    case Repo.query(
           "INSERT INTO patient_profile (key, value, updated_at) VALUES (?, ?, ?) ON CONFLICT(key) DO UPDATE SET value = excluded.value, updated_at = excluded.updated_at",
           [key, value, now]
         ) do
      {:ok, _} ->
        {:ok, %{key: key, value: value, updated_at: now}}

      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc """
  Delete a profile entry.
  """
  def delete(key) do
    case Repo.query("DELETE FROM patient_profile WHERE key = ?", [key]) do
      {:ok, _} -> :ok
      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  Update patient profile from LLM extraction result.
  Takes a map of key-value pairs and upserts them.
  """
  def update_from_distillation(kv_map) when is_map(kv_map) do
    Enum.each(kv_map, fn {key, value} ->
      put(key, value)
    end)
  end
end
