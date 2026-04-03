defmodule HerrFreud.Output.Writer do
  @moduledoc """
  Writes session transcripts to the sessions directory.
  """
  require Logger

  @doc """
  Write a session transcript to disk.

  Expects a map with:
    - id: session ID
    - date: Date
    - style: interaction style name
    - source_lang: original language
    - raw_transcript: original transcript (may be nil for audio)
    - english_transcript: translated transcript
    - response: Herr Freud's response
  """
  def write_session(session) do
    data_folder = Application.get_env(:herr_freud, :herr_freud_data_folder) || "./data"
    sessions_dir = Path.join(data_folder, "sessions")

    # Ensure directory exists
    File.mkdir_p!(sessions_dir)

    date_str = session.date |> Date.to_iso8601()
    filename = "#{date_str}_#{session.id}.md"
    filepath = Path.join(sessions_dir, filename)

    content = build_session_content(session)

    case File.write(filepath, content) do
      :ok ->
        Logger.info("Session written: #{filepath}")
        {:ok, filepath}

      {:error, reason} ->
        Logger.error("Failed to write session: #{inspect(reason)}")
        {:error, reason}
    end
  end

  defp build_session_content(session) do
    """
    ---
    date: #{session.date |> Date.to_iso8601()}
    session_id: #{session.id}
    style: #{session.style}
    source_language: #{session.source_lang}
    ---

    ## Patient Entry (original)

    #{session.raw_transcript || "[Audio — no raw transcript stored]"}

    ## Patient Entry (English)

    #{session.english_transcript}

    ## Herr Freud

    #{session.response}
    """
  end

  @doc """
  Write a nudge to the nudges directory.
  """
  def write_nudge(nudge) do
    data_folder = Application.get_env(:herr_freud, :herr_freud_data_folder) || "./data"
    nudges_dir = Path.join(data_folder, "nudges")

    File.mkdir_p!(nudges_dir)

    date_str = Date.utc_today() |> Date.to_iso8601()
    filename = "#{date_str}_nudge.md"
    filepath = Path.join(nudges_dir, filename)

    case File.write(filepath, nudge) do
      :ok ->
        Logger.info("Nudge written: #{filepath}")
        {:ok, filepath}

      {:error, reason} ->
        {:error, reason}
    end
  end
end
