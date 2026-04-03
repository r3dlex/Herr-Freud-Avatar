defmodule HerrFreud.Style.ManagerTest do
  use ExUnit.Case, async: true
  alias HerrFreud.Style.Manager

  describe "get_active_style/0" do
    test "returns the default style when no styles are seeded" do
      style = Manager.get_active_style()
      assert style != nil
      assert style.name == "single_question"
      assert style.id == "default"
    end
  end

  describe "switch_style/1" do
    test "returns error for unknown style when no styles are seeded" do
      assert Manager.switch_style("nonexistent") == {:error, :style_not_found}
      assert Manager.switch_style("conversational") == {:error, :style_not_found}
    end
  end
end
