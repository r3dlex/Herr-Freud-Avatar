defmodule HerrFreud.Session.BuilderTest do
  use ExUnit.Case, async: false
  alias HerrFreud.Session.Builder

  describe "build_system_prompt/5" do
    test "rejects empty transcript" do
      assert Builder.build_system_prompt(nil, %{}, [], "") == {:error, :empty_transcript}
    end

    test "builds prompt with minimal args" do
      style = %{name: "single_question", description: "One question", config: ~s({"type":"single_question"})}
      assert {:ok, prompt} = Builder.build_system_prompt(style, %{}, [], "Hello, how are you?")
      assert prompt =~ "Herr Freud"
      assert prompt =~ "Hello, how are you?"
    end

    test "includes patient profile when present" do
      profile = %{"brother_conflict" => "ongoing", "sleep_issue" => "insomnia"}
      style = %{name: "single_question", description: "One question", config: ~s({"type":"single_question"})}
      assert {:ok, prompt} = Builder.build_system_prompt(style, profile, [], "Today was hard.")
      assert prompt =~ "brother_conflict"
      assert prompt =~ "insomnia"
    end

    test "includes memories when present" do
      memories = [%{content: "Patient mentioned conflict with brother"}]
      style = %{name: "single_question", description: "One question", config: ~s({"type":"single_question"})}
      assert {:ok, prompt} = Builder.build_system_prompt(style, %{}, memories, "Today was hard.")
      assert prompt =~ "conflict with brother"
    end

    test "includes companion notes when present" do
      style = %{name: "single_question", description: "One question", config: ~s({"type":"single_question"})}
      assert {:ok, prompt} = Builder.build_system_prompt(style, %{}, [], "Today.", "Focus on work stress")
      assert prompt =~ "Focus on work stress"
    end
  end
end
