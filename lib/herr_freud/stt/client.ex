defmodule HerrFreud.STT.Client do
  @moduledoc """
  HTTP client for the faster-whisper STT sidecar.
  """
  @behaviour HerrFreud.STT

  @sidecar_url Application.compile_env(:herr_freud, :stt_sidecar_url, "http://stt-sidecar:9001")

  @impl true
  def transcribe(file_path, language \\ nil) do
    body = %{
      file_path: file_path,
      language: language
    }

    headers = [{"Content-Type", "application/json"}]

    case :hackney.post(
           "#{@sidecar_url}/transcribe",
           headers,
           Jason.encode!(body),
           [:with_body]
         ) do
      {:ok, status, _headers, body} when status in 200..299 ->
        parse_transcribe_response(body)

      {:ok, status, _headers, body} ->
        {:error, {:http_error, status, body}}

      {:error, reason} ->
        {:error, {:network_error, reason}}
    end
  end

  defp parse_transcribe_response(body) do
    case Jason.decode!(body) do
      %{
        "transcript" => transcript,
        "detected_language" => detected_language,
        "confidence" => confidence,
        "duration_seconds" => duration
      } ->
        {:ok,
         %{
           transcript: transcript,
           detected_language: detected_language,
           confidence: confidence,
           duration_seconds: duration
         }}

      %{"transcript" => transcript} ->
        {:ok,
         %{
           transcript: transcript,
           detected_language: "en",
           confidence: 0.9,
           duration_seconds: 0.0
         }}
    end
  end
end
