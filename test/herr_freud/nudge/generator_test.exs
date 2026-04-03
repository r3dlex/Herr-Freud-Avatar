defmodule HerrFreud.Nudge.GeneratorTest do
  use ExUnit.Case, async: true
  alias HerrFreud.Nudge.Generator

  describe "generate_nudge/2" do
    test "generates nudge with empty profile" do
      # Uses LLM.Stub which returns a fixed string
      assert {:ok, nudge} = Generator.generate_nudge(%{}, [])
      assert is_binary(nudge)
      assert byte_size(nudge) > 0
    end

    test "generates nudge with profile data" do
      profile = %{"brother_conflict" => "ongoing"}
      assert {:ok, nudge} = Generator.generate_nudge(profile, [])
      assert is_binary(nudge)
    end
  end
end
