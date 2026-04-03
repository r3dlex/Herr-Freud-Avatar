defmodule HerrFreud.Memory.DistillerTest do
  use ExUnit.Case, async: false

  alias HerrFreud.Memory.Distiller

  # Inline stubs injected via Application.put_env/3 in individual test setups.
  # chat/2 is intentionally minimal — translate/3 is a no-op to satisfy the behaviour.

  defmodule ErrorStub do
    @behaviour HerrFreud.LLM
    def chat(_messages, _opts), do: {:error, :mock_llm_failure}
    def translate(text, _from, _to), do: {:ok, text}
  end

  defmodule PlainTextStub do
    @behaviour HerrFreud.LLM
    def chat(_messages, _opts), do: {:ok, "Memory A.\nMemory B.\nMemory C."}
    def translate(text, _from, _to), do: {:ok, text}
  end

  defmodule WhitespacePadStub do
    @behaviour HerrFreud.LLM
    def chat(_messages, _opts), do: {:ok, "  Memory with spaces.  \n  Another memory.  "}
    def translate(text, _from, _to), do: {:ok, text}
  end

  setup do
    # Restore default stub after every test to avoid cross-test pollution.
    on_exit(fn ->
      Application.put_env(:herr_freud, :llm_mod, HerrFreud.LLM.Stub)
    end)

    :ok
  end

  # ---------------------------------------------------------------------------
  # distill/2 — successful LLM responses
  # ---------------------------------------------------------------------------
  describe "distill/2 returns {:ok, list} on successful LLM response" do
    test "returns {:ok, list} when LLM returns a JSON array string" do
      # Default test config: llm_mod = HerrFreud.LLM.Stub → "[\"Memory one.\", \"Memory two.\"]"
      assert {:ok, memories} = Distiller.distill("Patient talked about their brother.")
      assert is_list(memories)
      assert length(memories) == 2
    end
  end

  describe "distill/2 parses JSON array correctly" do
    test "decodes JSON array of strings into a list" do
      {:ok, memories} = Distiller.distill("Patient talked about their brother.")
      assert is_list(memories)

      # Each element must be a decoded string, not raw JSON text.
      Enum.each(memories, fn m ->
        assert is_binary(m)
        refute String.starts_with?(m, "[")
        refute String.starts_with?(m, "{")
      end)
    end

    test "each decoded element is a valid binary string" do
      {:ok, memories} = Distiller.distill("Patient talked about their brother.")
      assert Enum.all?(memories, &is_binary/1)
    end
  end

  describe "distill/2 trims whitespace from memory strings" do
    test "strips leading and trailing whitespace from each memory" do
      Application.put_env(:herr_freud, :llm_mod, __MODULE__.WhitespacePadStub)

      {:ok, memories} = Distiller.distill("Session transcript.")

      # parse_distillation_response applies Enum.map(&String.trim/1) after JSON decode,
      # and the line-split fallback also trims. Every returned string must be clean.
      assert Enum.all?(memories, fn m -> m == String.trim(m) end)
      # The two padded lines must appear trimmed in the result.
      assert "Memory with spaces." in memories
      assert "Another memory." in memories
    end
  end

  describe "distill/2 falls back to line splitting when JSON parse fails" do
    test "returns up to 3 memories by splitting non-JSON response on newlines" do
      Application.put_env(:herr_freud, :llm_mod, __MODULE__.PlainTextStub)

      {:ok, memories} = Distiller.distill("Session transcript.")

      # PlainTextStub returns "Memory A.\nMemory B.\nMemory C."
      # parse_distillation_response: Jason.decode fails → split on "\n" → trim → reject "" → take 3
      assert length(memories) == 3
      assert "Memory A." in memories
      assert "Memory B." in memories
      assert "Memory C." in memories
    end
  end

  describe "distill/2 returns memories even when LLM returns plain text" do
    test "does not return an error when response is not valid JSON" do
      Application.put_env(:herr_freud, :llm_mod, __MODULE__.PlainTextStub)

      result = Distiller.distill("Some session transcript.")
      assert {:ok, memories} = result
      assert is_list(memories)
      assert memories != []
    end
  end

  describe "distill/2 accepts optional transcript text as first arg" do
    test "accepts a non-empty transcript string without raising" do
      assert {:ok, _memories} =
               Distiller.distill("Patient described recurring anxiety about work.")
    end

    test "accepts an empty transcript string without raising" do
      assert {:ok, _memories} = Distiller.distill("")
    end
  end

  describe "distill/2 builds correct prompt from transcript" do
    test "runs to completion when transcript is embedded in the prompt" do
      unique_marker = "UNIQUE_MARKER_#{:rand.uniform(99_999)}"
      transcript = "Patient mentioned #{unique_marker} during the session."

      Application.put_env(:herr_freud, :llm_mod, __MODULE__.PlainTextStub)

      # PlainTextStub ignores messages; we only verify distill/2 does not error
      # when the transcript is passed through build_distillation_prompt.
      assert {:ok, _memories} = Distiller.distill(transcript)
    end
  end

  describe "distill/2 propagates error tuple from LLM" do
    test "returns {:error, reason} when chat returns an error" do
      Application.put_env(:herr_freud, :llm_mod, __MODULE__.ErrorStub)

      assert {:error, :mock_llm_failure} = Distiller.distill("Any transcript.")
    end
  end
end
