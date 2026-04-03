defmodule HerrFreud.STT do
  @moduledoc """
  Behaviour for speech-to-text providers.
  """

  @type transcript_result ::
          {:ok,
           %{
             transcript: String.t(),
             detected_language: String.t(),
             confidence: float(),
             duration_seconds: float()
           }}
          | {:error, term()}

  @doc """
  Transcribe an audio file. Language override optional.
  """
  @callback transcribe(file_path :: String.t(), language :: String.t() | nil) ::
            transcript_result()
end
