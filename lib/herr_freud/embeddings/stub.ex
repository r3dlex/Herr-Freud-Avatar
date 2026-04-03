defmodule HerrFreud.Embeddings.Stub do
  @moduledoc "Stub implementation for testing"
  @behaviour HerrFreud.Embeddings

  @impl true
  def embed(_text), do: {:ok, [0.0, 0.0, 0.0, 0.0, 0.0]}
end
