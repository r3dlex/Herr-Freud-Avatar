defmodule HerrFreud.Cron.HandlerTest do
  use ExUnit.Case, async: true
  alias HerrFreud.Cron.Handler

  describe "daily_nudge_check" do
    test "triggers nudge when no sessions exist" do
      # Handler will spawn the actual nudge generation
      # We just verify the handler can be called
      assert :ok = Handler.run_daily_nudge_check()
    end
  end
end
