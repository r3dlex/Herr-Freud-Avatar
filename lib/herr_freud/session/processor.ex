defmodule HerrFreud.Session.Processor do
  @moduledoc """
  Orchestrates a full therapy session from input file to response.
  """
  require Logger
  alias HerrFreud.Memory.Retriever
  alias HerrFreud.Memory.Store
  alias HerrFreud.Output.Writer

  @supported_audio_extensions [".mp3", ".wav", ".m4a", ".ogg", ".webm"]

  @doc """
  Process a file dropped into the input directory.
  Automatically detects whether it's audio or text.
  """
  def process_file(file_path) do
    ext = Path.extname(file_path) |> String.downcase()

    result =
      if ext in @supported_audio_extensions do
        process_audio_file(file_path)
      else
        process_text_file(file_path)
      end

    case result do
      {:ok, _session} ->
        :ok

      {:error, reason} ->
        Logger.error("Session processing failed for #{file_path}: #{inspect(reason)}")
        {:error, reason}
    end
  end

  @doc """
  Process an audio file: transcribe -> translate -> respond
  """
  def process_audio_file(file_path) do
    with {:ok, stt_result} <- stt_mod().transcribe(file_path, nil),
         {:ok, english_transcript} <- translate_if_needed(stt_result.transcript, stt_result.detected_language),
         companion_notes <- read_companion_notes(file_path),
         {:ok, response, memory_ids} <-
           generate_response_and_save(
             stt_result.transcript,
             english_transcript,
             stt_result.detected_language,
             "audio",
             companion_notes
           ) do
      Logger.info("Audio session processed successfully")
      {:ok, %{transcript: english_transcript, response: response, memory_ids: memory_ids}}
    end
  end

  @doc """
  Process a text file: read -> detect language -> translate -> respond
  """
  def process_text_file(file_path) do
    with {:ok, content} <- File.read(file_path),
         {text, source_lang, companion_notes} <- parse_text_content(content, file_path),
         {:ok, english_transcript} <- translate_if_needed(text, source_lang),
         {:ok, response, memory_ids} <-
           generate_response_and_save(
             text,
             english_transcript,
             source_lang,
             "text",
             companion_notes
           ) do
      Logger.info("Text session processed successfully")
      {:ok,
       %{
         transcript: english_transcript,
         source_lang: source_lang || "unknown",
         response: response,
         memory_ids: memory_ids
       }}
    end
  end

  # Internal

  defp stt_mod, do: Application.get_env(:herr_freud, :stt_mod, HerrFreud.STT.Client)
  defp llm_mod, do: Application.get_env(:herr_freud, :llm_mod, HerrFreud.LLM.MiniMax)
  defp embeddings_mod, do: Application.get_env(:herr_freud, :embeddings_mod, HerrFreud.Embeddings.MiniMax)

  defp translate_if_needed(text, "en"), do: {:ok, text}
  defp translate_if_needed(text, lang) when is_binary(lang) and lang != "en" do
    llm_mod().translate(text, lang, "en")
  end
  defp translate_if_needed(text, _), do: {:ok, text}

  defp parse_text_content(content, file_path) do
    notes = read_companion_notes(file_path)

    # Extract lang from frontmatter using a simple regex rather than YamlElixir
    # (YamlElixir.read_from_string returns the body content for frontmatter-style docs,
    # not the frontmatter metadata, so we use a direct pattern match instead)
    case Regex.run(~r/^---\s*\n(lang:\s*\S+)/, content) do
      [_, "lang: " <> lang] ->
        body = extract_body_after_front_matter(content)
        {body, String.trim(lang), notes}

      _ ->
        # No front matter with lang — treat as plain text
        trimmed = String.trim_leading(content)
        {trimmed, nil, notes}
    end
  end

  # Strips the yaml front matter (between the first two --- lines) and returns
  # the body content below them. Returns the full content if no front matter found.
  defp extract_body_after_front_matter(content) do
    # Reliable extraction: split on "---\n", require exactly 3+ parts,
    # parts[0]=="" indicates valid frontmatter, body is parts[2..end]
    parts = String.split(content, "---\n")

    if length(parts) >= 3 and hd(parts) == "" do
      body = Enum.slice(parts, 2, length(parts) - 2) |> Enum.join() |> String.trim()
      if body == "", do: content, else: body
    else
      content
    end
  end

  defp read_companion_notes(file_path) do
    base = Path.rootname(file_path)
    notes_path = base <> ".md"

    if File.exists?(notes_path) and notes_path != file_path do
      case File.read(notes_path) do
        {:ok, notes} -> String.trim(notes)
        _ -> nil
      end
    else
      nil
    end
  end

  defp generate_response_and_save(
          raw_transcript,
          english_transcript,
          source_lang,
          input_mode,
          companion_notes
        ) do
    session_id = Ecto.UUID.generate()

    # Get active style and patient profile
    style = HerrFreud.Style.Manager.get_active_style()
    {:ok, profile_entries} = HerrFreud.Profile.Store.get_all()
    profile_map = Map.new(profile_entries, fn %{key: k, value: v} -> {k, v} end)

    # Fetch relevant memories
    {:ok, memories} = Retriever.fetch_for_text(english_transcript, 10)

    # Build prompt and generate response
    {:ok, system_prompt} = HerrFreud.Session.Builder.build_system_prompt(
      style, profile_map, memories, english_transcript, companion_notes
    )

    messages = [
      %{role: "system", content: system_prompt},
      %{role: "user", content: english_transcript}
    ]

    with {:ok, response} <- llm_mod().chat(messages, []) do
      # Generate embedding for the transcript
      embedding = case embeddings_mod().embed(english_transcript) do
        {:ok, emb} -> :erlang.term_to_binary(emb)
        _ -> nil
      end

      # Save session
      {:ok, _session} = Store.insert_session(%{
        id: session_id,
        date: Date.utc_today(),
        input_mode: input_mode,
        source_lang: source_lang || "unknown",
        raw_transcript: raw_transcript,
        english_transcript: english_transcript,
        response: response,
        style_used: style.name,
        embedding: embedding
      })

      # Distill memories
      {:ok, memory_strings} = HerrFreud.Memory.Distiller.distill(english_transcript)

      memory_ids = for content <- memory_strings do
        {:ok, emb} = embeddings_mod().embed(content)
        emb_binary = :erlang.term_to_binary(emb)
        recency = Retriever.compute_recency_score(0)

        {:ok, memory} = Store.insert_memory(%{
          session_id: session_id,
          content: content,
          embedding: emb_binary,
          recency_score: recency
        })
        memory.id
      end

      # Write output file
      session_map = %{
        id: session_id,
        date: Date.utc_today(),
        style: style.name,
        source_lang: source_lang || "unknown",
        raw_transcript: raw_transcript,
        english_transcript: english_transcript,
        response: response
      }
      Writer.write_session(session_map)

      # Archive to librarian
      archive_session(session_map)

      {:ok, response, memory_ids}
    end
  end

  defp archive_session(session) do
    # Send to librarian via IAMQ HTTP client
    HerrFreud.IAMQ.HttpClient.send(%{
      from: "herr_freud_agent",
      to: "librarian_agent",
      type: "request",
      priority: "NORMAL",
      subject: "archive",
      body: %{
        capability: "archive",
        file_path: "/sessions/#{Date.utc_today() |> Date.to_iso8601()}_#{session.id}.md",
        library: "herr_freud",
        tags: ["therapy", "diary", "session"],
        date: Date.utc_today() |> Date.to_iso8601()
      }
    })
  rescue
    _ ->
      Logger.warning("Failed to archive session to librarian (IAMQ may be unreachable)")
      :ok
  end
end
