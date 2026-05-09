defmodule HerrFreud.Embeddings.Bumblebee do
  @moduledoc """
  Native Elixir embeddings using Bumblebee + all-MiniLM-L6-v2.

  Model: sentence-transformers/all-MiniLM-L6-v2 (~80MB, loaded from HuggingFace)
  Runtime: Bumblebee (Elixir) + Nx for inference
  Output: 384-dimension vectors

  Falls back to a 384-dim zero vector when Bumblebee/model loading fails
  (e.g. no GPU, HuggingFace unreachable, missing native dependencies).
  """

  @behaviour HerrFreud.Embeddings

  require Logger

  # all-MiniLM-L6-v2 produces 384-dimensional embeddings
  @embedding_dim 384
  @model_id "sentence-transformers/all-MiniLM-L6-v2"

  @impl true
  def embed(text) when is_binary(text) do
    case load_model() do
      {:ok, serving} ->
        result = Nx.Serving.run(serving, text)
        embedding = extract_embedding(result)
        {:ok, embedding}

      {:error, reason} ->
        Logger.warning("Bumblebee model unavailable: #{inspect(reason)}, returning zero vector")
        {:ok, List.duplicate(0.0, @embedding_dim)}
    end
  end

  # Returns {:ok, serving} or {:error, reason}
  defp load_model do
    case Process.get(:bumblebee_serving) do
      nil ->
        load_and_cache_serving()

      serving ->
        {:ok, serving}
    end
  end

  defp load_and_cache_serving do
    try do
      serving = Bumblebee.Text.text_embedding(@model_id, embedding_size: @embedding_dim)
      Process.put(:bumblebee_serving, serving)
      {:ok, serving}
    rescue
      reason ->
        {:error, reason}
    catch
      kind, reason ->
        {:error, {kind, reason}}
    end
  end

  # Bumblebee.Text.text_embedding returns %{embedding: Nx.Tensor.t()}
  defp extract_embedding(%{embedding: embedding}) do
    embedding |> Nx.to_list()
  end
end
