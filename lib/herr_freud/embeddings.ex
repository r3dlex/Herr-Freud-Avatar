defmodule HerrFreud.Embeddings do
  @moduledoc """
  Behaviour for embedding providers.

  Implement this behaviour to add a new embedding provider.
  """

  @type embedding_result :: {:ok, [float()]} | {:error, term()}

  @doc """
  Generate an embedding vector for the given text.
  Returns a list of floats.
  """
  @callback embed(text :: String.t()) :: embedding_result()
end
