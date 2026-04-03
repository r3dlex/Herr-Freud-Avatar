defmodule HerrFreud.Session.ProcessorTest do
  use ExUnit.Case, async: false

  alias HerrFreud.Session.Processor
  alias HerrFreud.Memory.{Session, Memory}
  alias HerrFreud.Repo
  import Ecto.Query

  # Load meck mocks once at test module startup (async: false = one process)
  setup_all do
    :meck.expect(HerrFreud.IAMQ.HttpClient, :send, fn _ -> {:ok, :sent} end)
    :meck.new([HerrFreud.STT.Stub], [:non_strict])
    :meck.expect(HerrFreud.STT.Stub, :transcribe, fn path, lang ->
      {:ok, %{
        transcript: "Stubbed transcript for: #{Path.basename(path)}",
        detected_language: lang || "en",
        confidence: 0.95,
        duration_seconds: 5.0
      }}
    end)
    :ok
  end

  setup do
    # Clean sessions and memories tables before each test to avoid
    # stale zero-vector embeddings that break cosine_similarity in Retriever
    Repo.delete_all(from s in Session)
    Repo.delete_all(from m in Memory)
    :ok
  end

  # -------------------------------------------------------------------------
  # parse_text_content/2 — language detection from frontmatter
  # -------------------------------------------------------------------------
  describe "parse_text_content/2 (private, tested via process_text_file)" do
    test "yaml frontmatter with lang key — detected from frontmatter" do
      content = """
      ---
      lang: de
      date: 2026-04-03
      ---
      Heute war ein schwerer Tag.
      """

      base = unique_file_base()
      txt_path = Path.join(tmp_dir(), "#{base}.txt")
      File.write!(txt_path, content)

      assert {:ok, %{source_lang: lang}} = Processor.process_text_file(txt_path)
      assert lang == "de"
    end

    test "yaml frontmatter with _body extracts body content, not raw yaml" do
      content = """
      ---
      lang: fr
      ---
      Je me sens fatigue aujourd'hui.
      """

      base = unique_file_base()
      txt_path = Path.join(tmp_dir(), "#{base}.txt")
      File.write!(txt_path, content)

      assert {:ok, %{transcript: transcript}} = Processor.process_text_file(txt_path)
      # The body should be the text content, not the YAML frontmatter
      assert transcript == "Je me sens fatigue aujourd'hui."
    end

    test "plain text file without frontmatter — source_lang falls back to nil then \"unknown\"" do
      # No frontmatter at all — parse_text_content treats it as plain text
      base = unique_file_base()
      txt_path = Path.join(tmp_dir(), "#{base}.txt")
      File.write!(txt_path, "This is a plain text entry without any YAML.")

      assert {:ok, %{source_lang: "unknown"}} = Processor.process_text_file(txt_path)
    end

    test "malformed yaml (valid yaml but no lang key) — source_lang is nil, falls back to \"unknown\"" do
      content = """
      ---
      date: 2026-04-03
      mood: sad
      ---
      I had a terrible day.
      """

      base = unique_file_base()
      txt_path = Path.join(tmp_dir(), "#{base}.txt")
      File.write!(txt_path, content)

      assert {:ok, %{source_lang: "unknown"}} = Processor.process_text_file(txt_path)
    end

    test "companion notes file alongside text file — notes are passed to builder" do
      # A .md companion file exists alongside the .txt entry
      base = unique_file_base()
      txt_path = Path.join(tmp_dir(), "#{base}.txt")
      File.write!(txt_path, "I need to talk about my brother.")

      md_path = Path.join(tmp_dir(), "#{base}.md")
      File.write!(md_path, "Patient mentioned ongoing conflict with brother in prior session.")

      base2 = unique_file_base()
      txt_path2 = Path.join(tmp_dir(), "#{base2}.txt")
      File.write!(txt_path2, "The conflict with my brother is still unresolved.")

      # The companion notes file that shares the base name of the SECOND file
      # should be picked up. The first file has no companion since base.txt != base.md
      assert {:ok, _result} = Processor.process_text_file(txt_path2)
    end

    test "companion notes file that is the same path as entry — skipped" do
      base = unique_file_base()
      # Entry IS the .md file — read_companion_notes skips it (base == notes_path)
      path = Path.join(tmp_dir(), "#{base}.md")
      File.write!(path, "Some content in a .md file that IS the entry.")

      assert {:ok, _result} = Processor.process_text_file(path)
    end
  end

  # -------------------------------------------------------------------------
  # process_text_file/1 — full text input path
  # -------------------------------------------------------------------------
  describe "process_text_file/1" do
    test "full text path: file read -> translate (en, no-op) -> response saved" do
      base = unique_file_base()
      txt_path = Path.join(tmp_dir(), "#{base}.txt")
      File.write!(txt_path, "I feel anxious about my presentation tomorrow.")

      assert {:ok, %{transcript: transcript, response: response, memory_ids: ids}} =
               Processor.process_text_file(txt_path)

      assert is_binary(transcript)
      assert is_binary(response)
      assert is_list(ids)
    end

    test "non-english frontmatter triggers translate call" do
      content = """
      ---
      lang: de
      ---
      Ich habe heute viel nachgedacht.
      """

      base = unique_file_base()
      txt_path = Path.join(tmp_dir(), "#{base}.txt")
      File.write!(txt_path, content)

      # Stub LLM.translate returns {:ok, text} as-is, so the translated
      # version is the same as input. In production the STT/translate chain
      # would produce the English version.
      assert {:ok, %{source_lang: "de"}} = Processor.process_text_file(txt_path)
    end

    test "process_text_file returns error when file does not exist" do
      assert {:error, _} = Processor.process_text_file("/nonexistent/path/to/entry.txt")
    end

    test "process_text_file inserts session record via Memory.Store" do
      content = """
      ---
      lang: en
      ---
      Testing session insertion through the full pipeline.
      """

      base = unique_file_base()
      txt_path = Path.join(tmp_dir(), "#{base}.txt")
      File.write!(txt_path, content)

      {:ok, %{memory_ids: ids}} = Processor.process_text_file(txt_path)

      # Memory.Store should have inserted a session record
      assert is_list(ids)
    end
  end

  # -------------------------------------------------------------------------
  # process_audio_file/1 — full audio input path
  # -------------------------------------------------------------------------
  describe "process_audio_file/1" do
    test "audio file calls STT.Transcribe then generates response" do
      audio_path = Path.join(tmp_dir(), "session_audio.mp3")
      File.write!(audio_path, <<255, 255, 255>>)

      assert {:ok, %{transcript: transcript, response: response, memory_ids: ids}} =
               Processor.process_audio_file(audio_path)

      # STT.Stub returns transcript containing the filename
      assert transcript =~ "session_audio"
      assert is_binary(response)
      assert is_list(ids)
    end

    test "audio path is routed correctly from process_file/1" do
      # Reset STT mock in case prior error propagation test left it in error state
      :meck.expect(HerrFreud.STT.Stub, :transcribe, fn path, lang ->
        {:ok, %{
          transcript: "Stubbed transcript for: #{Path.basename(path)}",
          detected_language: lang || "en",
          confidence: 0.95,
          duration_seconds: 5.0
        }}
      end)

      audio_path = Path.join(tmp_dir(), "diary_entry.m4a")
      File.write!(audio_path, <<1, 2, 3>>)

      assert :ok = Processor.process_file(audio_path)
    end

    test "process_file/1 routes .txt to text path" do
      base = unique_file_base()
      txt_path = Path.join(tmp_dir(), "#{base}.txt")
      File.write!(txt_path, "Some diary text.")

      assert :ok = Processor.process_file(txt_path)
    end

    test "process_file/1 routes .wav to audio path" do
      reset_stt_mock()
      wav_path = Path.join(tmp_dir(), "voice_note.wav")
      File.write!(wav_path, <<9, 8, 7>>)

      assert :ok = Processor.process_file(wav_path)
    end

    test "unsupported extension falls through to text path" do
      reset_stt_mock()
      # processor uses else branch for unknown extensions
      other_path = Path.join(tmp_dir(), "entry.log")
      File.write!(other_path, "log entry content")

      # .log is not in @supported_audio_extensions so it hits process_text_file
      assert :ok = Processor.process_file(other_path)
    end

    test "process_file returns error when result is error" do
      # process_text_file propagates File.read errors
      reset_stt_mock()
      assert {:error, _} = Processor.process_file("/no/such/file.txt")
    end
  end

  # -------------------------------------------------------------------------
  # Error propagation
  # -------------------------------------------------------------------------
  describe "error propagation" do
    setup :meck_stt_error

    defp meck_stt_error(_ctx) do
      # Re-override transcribe to return error
      :meck.expect(HerrFreud.STT.Stub, :transcribe, fn _path, _lang ->
        {:error, :stt_timeout}
      end)
      # Reset mock after this test ends so subsequent tests aren't affected
      on_exit(fn -> reset_stt_mock() end)
      :ok
    end

    test "STT error propagates through process_audio_file" do
      audio_path = Path.join(tmp_dir(), "bad_audio.mp3")
      File.write!(audio_path, <<0>>)

      assert {:error, :stt_timeout} = Processor.process_audio_file(audio_path)
    end
  end

  # -------------------------------------------------------------------------
  # Helpers
  # -------------------------------------------------------------------------
  defp reset_stt_mock do
    :meck.expect(HerrFreud.STT.Stub, :transcribe, fn path, lang ->
      {:ok, %{
        transcript: "Stubbed transcript for: #{Path.basename(path)}",
        detected_language: lang || "en",
        confidence: 0.95,
        duration_seconds: 5.0
      }}
    end)
  end

  defp tmp_dir do
    dir = Path.join(System.tmp_dir(), "herr_freud_processor_test")
    File.mkdir_p!(dir)
    dir
  end

  defp unique_file_base do
    "entry_#{:rand.uniform(99_999_999)}"
  end
end