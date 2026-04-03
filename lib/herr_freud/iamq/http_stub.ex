defmodule HerrFreud.IAMQ.HttpStub do
  @moduledoc "Stub HTTP client for testing"
  @behaviour HerrFreud.IAMQ.HTTP

  def send(_message), do: :ok
  def poll_inbox, do: :ok
end
