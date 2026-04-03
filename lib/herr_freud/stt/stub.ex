defmodule HerrFreud.STT.Stub do
  @moduledoc "Stub implementation for testing"
  @behaviour HerrFreud.STT

  @impl true
  def transcribe(file_path, lang \\ nil) do
    {:ok,
     %{
       transcript: "Stubbed transcript for: #{Path.basename(file_path)}",
       detected_language: lang || "en",
       confidence: 0.95,
       duration_seconds: 5.0
     }}
  end
end
