defmodule HerrFreud.Embeddings.Centralized do
  @moduledoc """
  Embeddings implementation using the centralized Openclaw MLX embeddings service.
  Replaces the MiniMax embeddings implementation with a local, memory-optimized service.
  """

  @behaviour HerrFreud.Embeddings

  require Logger

  @impl true
  def embed(text) when is_binary(text) do
    url = System.get_env("EMBEDDINGS_URL", "http://host.docker.internal:18795")
    body = Jason.encode!(%{texts: [text], normalize: true})

    case :hackney.post(
           "#{url}/embed",
           [{"Content-Type", "application/json"}, {"Accept", "application/json"}],
           body,
           [:with_body]
         ) do
      {:ok, 200, _headers, response_body} ->
        case Jason.decode(response_body) do
          {:ok, %{"embeddings" => [embedding | _]}} ->
            {:ok, embedding}

          {:ok, other} ->
            {:error, "Unexpected response format: #{inspect(other)}"}

          {:error, reason} ->
            {:error, "Failed to decode response: #{inspect(reason)}"}
        end

      {:ok, status, _headers, body} ->
        {:error, "Embeddings service returned status #{status}: #{body}"}

      {:error, reason} ->
        Logger.warning("Embeddings service unavailable: #{inspect(reason)}")
        {:error, "Embeddings service unavailable: #{inspect(reason)}"}
    end
  end
end
