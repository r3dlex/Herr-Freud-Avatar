defmodule HerrFreud.Output.WriterTest do
  use ExUnit.Case, async: true
  alias HerrFreud.Output.Writer

  describe "write_session/1" do
    test "writes session file to correct directory" do
      # Use tmp directory for test
      tmp_dir = System.tmp_dir!()
      File.mkdir_p!(Path.join(tmp_dir, "sessions"))

      Application.put_env(:herr_freud, :herr_freud_data_folder, tmp_dir)

      session = %{
        id: "test-123",
        date: ~D[2026-04-03],
        style: "single_question",
        source_lang: "de",
        raw_transcript: "Heute war ein schwerer Tag.",
        english_transcript: "Today was a hard day.",
        response: "Thank you for sharing that."
      }

      assert {:ok, path} = Writer.write_session(session)
      assert path =~ "sessions/"
      assert path =~ "2026-04-03_test-123.md"

      assert File.read!(path) =~ "Herr Freud"
      assert File.read!(path) =~ "Today was a hard day."
    after
      Application.put_env(:herr_freud, :herr_freud_data_folder, nil)
    end
  end
end
