defmodule HerrFreud.Input.WatcherTest do
  use ExUnit.Case, async: true

  describe "valid_input_file?" do
    alias HerrFreud.Input.Watcher

    test "accepts supported audio extensions" do
      assert Watcher.valid_input_file?("/data/input/test.mp3")
      assert Watcher.valid_input_file?("/data/input/test.wav")
      assert Watcher.valid_input_file?("/data/input/test.m4a")
      assert Watcher.valid_input_file?("/data/input/de_test.md")
    end

    test "rejects unsupported files" do
      refute Watcher.valid_input_file?("/data/input/test.pdf")
      refute Watcher.valid_input_file?("/data/input/test.exe")
    end

    test "rejects directories" do
      refute Watcher.valid_input_file?("/data/input/")
    end
  end
end
