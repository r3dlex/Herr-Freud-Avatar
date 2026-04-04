defmodule HerrFreud.LLM.MiniMax do
  @moduledoc """
  MiniMax chat completions API integration.
  """
  @behaviour HerrFreud.LLM

  @api_base "https://api.minimax.chat/v1"

  @impl true
  def chat(messages, opts \\ []) do
    api_key = Application.get_env(:herr_freud, :minimax_api_key) || raise("MINIMAX_API_KEY not set")
    model = Application.get_env(:herr_freud, :minimax_model) || "abab6.5s-chat"

    body = %{
      model: model,
      messages: messages,
      temperature: Keyword.get(opts, :temperature, 0.7),
      max_tokens: Keyword.get(opts, :max_tokens, 1024)
    }

    headers = [
      {"Authorization", "Bearer #{api_key}"},
      {"Content-Type", "application/json"}
    ]

    case Req.post("#{@api_base}/text/chatcompletion_v2",
           headers: headers,
           body: Jason.encode!(body),
           decode_body: false
         ) do
      {:ok, %{status: status, body: body}} when status in 200..299 ->
        {:ok, parse_chat_response(body)}

      {:ok, %{status: status, body: body}} ->
        {:error, {:http_error, status, body}}

      {:error, reason} ->
        {:error, {:network_error, reason}}
    end
  end

  @impl true
  def translate(text, from_lang, to_lang) do
    messages = [
      %{
        role: "system",
        content:
          "You are a professional medical translator. Translate the following text from #{from_lang} to #{to_lang}. Preserve the tone and nuance. Only output the translation, nothing else."
      },
      %{role: "user", content: text}
    ]

    case chat(messages, temperature: 0.3, max_tokens: 4096) do
      {:ok, translation} -> {:ok, String.trim(translation)}
      {:error, _} = error -> error
    end
  end

  defp parse_chat_response(body) do
    case Jason.decode!(body) do
      %{"choices" => [%{"messages" => [%{"text" => text} | _]}]} ->
        text

      %{"choices" => [%{"messages" => messages}]} when is_list(messages) ->
        messages |> Enum.reverse() |> hd() |> Map.get("text", "")

      %{"choices" => [%{"messages" => messages_list}]} when is_list(messages_list) ->
        Enum.map_join(messages_list, fn m -> Map.get(m, "text", "") end)
    end
  end
end
