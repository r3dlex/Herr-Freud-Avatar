defmodule HerrFreud.Profile.StoreTest do
  use ExUnit.Case, async: true
  alias HerrFreud.Profile.Store

  describe "get/1" do
    test "returns not_found when key does not exist" do
      assert Store.get("nonexistent_key") == {:error, :not_found}
    end
  end

  describe "put/2" do
    test "inserts a profile entry" do
      assert {:ok, entry} = Store.put("test_key", "test_value")
      assert entry.key == "test_key"
      assert entry.value == "test_value"
    end

    test "updates existing key" do
      Store.put("update_key", "original")
      assert {:ok, updated} = Store.put("update_key", "updated")
      assert updated.value == "updated"
    end
  end

  describe "get_all/0" do
    test "returns all entries" do
      Store.put("key1", "value1")
      Store.put("key2", "value2")
      assert {:ok, entries} = Store.get_all()
      assert length(entries) >= 2
    end
  end
end