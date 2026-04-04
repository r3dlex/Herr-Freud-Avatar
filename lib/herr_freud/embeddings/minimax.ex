defmodule HerrFreud.Embeddings.MiniMax do
  @moduledoc """
  MiniMax embeddings API integration.
  """
  @behaviour HerrFreud.Embeddings

  @api_base "https://api.minimax.chat/v1"

  @impl true
  def embed(text) do
    api_key = Application.get_env(:herr_freud, :minimax_api_key) || raise("MINIMAX_API_KEY not set")
    model = Application.get_env(:herr_freud, :minimax_embedding_model) || "embo-01"

    body = %{
      model: model,
      texts: [text]
    }

    headers = [
      {"Authorization", "Bearer #{api_key}"},
      {"Content-Type", "application/json"}
    ]

    case Req.post("#{@api_base}/embeddings",
           headers: headers,
           body: Jason.encode!(body),
           decode_body: false
         ) do
      {:ok, %{status: status, body: body}} when status in 200..299 ->
        {:ok, parse_embedding_response(body)}

      {:ok, %{status: status, body: body}} ->
        {:error, {:http_error, status, body}}

      {:error, reason} ->
        {:error, {:network_error, reason}}
    end
  end

  defp parse_embedding_response(body) do
    case Jason.decode!(body) do
      %{"vectors" => [[h | _] = vector]} when is_number(h) ->
        vector

      %{"vectors" => [%{"embedding" => embedding}]} ->
        embedding

      %{"data" => [%{"embedding" => embedding}]} ->
        embedding
    end
  end
end
