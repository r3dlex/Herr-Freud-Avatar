defmodule HerrFreud.LLM.Stub do
  @moduledoc """
  Stub implementation for testing.
  Works in two modes:
  - Function-only (no Agent): returns default stub responses. For use in simple unit tests.
  - Agent-based: started as GenServer, supports dynamic response injection via set_response/1.
    For integration tests requiring error path coverage.

  To use Agent mode, add to your test setup:
      {:ok, _} = HerrFreud.LLM.Stub.start_link(initial_value: {:ok, default_response()})
  And clean up with:
      Agent.stop(HerrFreud.LLM.Stub)
  """
  @behaviour HerrFreud.LLM

  @default_response "[\"Patient expressed ongoing conflict with their brother about boundaries.\", \"Patient mentioned they haven't been sleeping well for the past week.\"]"

  # ---------------------------------------------------------------------------
  # Agent-based mode (opt-in per-test)
  # ---------------------------------------------------------------------------

  def start_link(opts \\ []) do
    Agent.start_link(
      fn -> Keyword.get(opts, :initial_value, {:ok, @default_response}) end,
      name: __MODULE__
    )
  end

  def set_response(response) do
    if Process.whereis(__MODULE__) do
      Agent.update(__MODULE__, fn _ -> response end)
    else
      :ok
    end
  end

  def reset_response do
    set_response({:ok, @default_response})
  end

  # ---------------------------------------------------------------------------
  # Behaviour callbacks
  # ---------------------------------------------------------------------------

  @impl true
  def chat(_messages, _opts) do
    # Fall back to pure function if Agent not running (backwards compatible)
    if Process.whereis(__MODULE__) do
      Agent.get(__MODULE__, & &1)
    else
      {:ok, @default_response}
    end
  end

  @impl true
  def translate(text, _from, _to), do: {:ok, text}

  # ---------------------------------------------------------------------------
  # Child spec for supervision
  # ---------------------------------------------------------------------------

  def child_spec(opts \\ []) do
    %{id: __MODULE__, start: {__MODULE__, :start_link, [opts]}}
  end
end
