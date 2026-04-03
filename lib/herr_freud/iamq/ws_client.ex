defmodule HerrFreud.IAMQ.WsClient do
  @moduledoc """
  WebSocket client for real-time IAMQ communication.
  Uses WebSockex for the WebSocket connection.
  """
  use WebSockex
  require Logger

  @agent_id Application.compile_env(:herr_freud, :iamq_agent_id, "herr_freud_agent")
  @heartbeat_ms Application.compile_env(:herr_freud, :iamq_heartbeat_ms, 300_000)

  def start_link(_opts) do
    ws_url = Application.get_env(:herr_freud, :iamq_ws_url) || "ws://127.0.0.1:18793/ws"
    WebSockex.start_link(ws_url, __MODULE__, %{}, name: __MODULE__)
  end

  @impl true
  def handle_connect(_conn, state) do
    Logger.info("IAMQ WebSocket connected")
    register()

    # Start heartbeat
    heartbeat_timer = schedule_heartbeat()

    {:ok, %{state | heartbeat_timer: heartbeat_timer}}
  end

  @impl true
  def handle_disconnect(conn_data, state) do
    Logger.warning("IAMQ WebSocket disconnected: #{inspect(conn_data)}")

    if state.heartbeat_timer do
      Process.cancel_timer(state.heartbeat_timer)
    end

    # Attempt reconnect
    schedule_reconnect()

    {:ok, %{state | heartbeat_timer: nil}}
  end

  @impl true
  def handle_frame({:text, frame}, state) do
    case Jason.decode(frame) do
      {:ok, message} ->
        handle_ws_message(message)
        {:ok, state}

      _ ->
        {:ok, state}
    end
  end

  def handle_frame(_frame, state), do: {:ok, state}

  @impl true
  def handle_info(:heartbeat, state) do
    send_heartbeat()
    timer = schedule_heartbeat()
    {:ok, %{state | heartbeat_timer: timer}}
  end

  def handle_info(:reconnect, state) do
    ws_url = Application.get_env(:herr_freud, :iamq_ws_url) || "ws://127.0.0.1:18793/ws"
    WebSockex.start_link(ws_url, __MODULE__, %{})
    {:ok, state}
  end

  defp register do
    register_msg = %{
      agent_id: @agent_id,
      capabilities: [
        "diary_intake",
        "session_response",
        "memory_recall",
        "style_switch",
        "patient_nudge",
        "session_archive"
      ]
    }

    send_frame(Jason.encode!(register_msg))
  end

  defp send_heartbeat do
    heartbeat_msg = %{
      type: "heartbeat",
      agent_id: @agent_id,
      timestamp: DateTime.utc_now() |> DateTime.to_iso8601()
    }

    try do
      send_frame(Jason.encode!(heartbeat_msg))
    rescue
      _ -> :ok
    end
  end

  defp schedule_heartbeat do
    Process.send_after(self(), :heartbeat, @heartbeat_ms)
  end

  defp schedule_reconnect do
    Process.send_after(self(), :reconnect, 30_000)
  end

  defp send_frame(frame) do
    try do
      WebSockex.send_frame(__MODULE__, {:text, frame})
    rescue
      _ -> :ok
    end
  end

  defp handle_ws_message(msg) do
    subject = msg["subject"]

    case subject do
      "style_switch" ->
        style_name = msg["body"] && msg["body"]["style"]
        if style_name, do: HerrFreud.Style.Manager.switch_style(style_name)

      "cron::daily_nudge_check" ->
        HerrFreud.Cron.Handler.run_daily_nudge_check()

      "cron::weekly_summary" ->
        HerrFreud.Cron.Handler.run_weekly_summary()

      "session_request" ->
        Logger.info("Session request via WebSocket")

      _ ->
        Logger.debug("WebSocket message: #{inspect(subject)}")
    end
  rescue
    e ->
      Logger.error("WS message error: #{inspect(e)}")
  end
end
