defmodule HerrFreud.Style.Manager do
  @moduledoc """
  Loads and manages the active interaction style.
  """
  use GenServer
  alias HerrFreud.Repo
  alias HerrFreud.Style.Manager.Style

  defmodule Style do
    @enforce_keys [:id, :name, :description, :config]
    defstruct [:id, :name, :description, :active, config: %{}]

    @default_config %{"greeting" => "Hello", "closing" => "Take your time."}

    def default do
      %__MODULE__{
        id: "default",
        name: "single_question",
        description: "Herr Freud listens fully, reflects briefly, then asks exactly one question.",
        active: true,
        config: @default_config
      }
    end
  end

  # Client API

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  @doc """
  Get the currently active interaction style.
  """
  def get_active_style do
    GenServer.call(__MODULE__, :get_active_style)
  end

  @doc """
  Switch to a different interaction style by name.
  """
  def switch_style(style_name) do
    GenServer.call(__MODULE__, {:switch_style, style_name})
  end

  # Server callbacks

  @impl true
  def init(_opts) do
    style = load_active_style()
    {:ok, %{style: style}}
  end

  @impl true
  def handle_call(:get_active_style, _from, %{style: style} = state) do
    {:reply, style, state}
  end

  @impl true
  def handle_call({:switch_style, style_name}, _from, state) do
    case do_switch(style_name) do
      {:ok, new_style} ->
        {:reply, {:ok, new_style}, %{state | style: new_style}}

      {:error, reason} ->
        {:reply, {:error, reason}, state}
    end
  end

  # Internal

  defp load_active_style do
    case Repo.query(
           "SELECT id, name, description, active, config FROM interaction_styles WHERE active = 1 LIMIT 1"
         ) do
      {:ok, %{rows: [[id, name, desc, active, config_json]]}} ->
        {:ok, config} = Jason.decode(config_json)
        %Style{id: id, name: name, description: desc, active: active, config: config}

      _ ->
        Style.default()
    end
  end

  defp do_switch(style_name) do
    # Deactivate all styles
    Repo.query("UPDATE interaction_styles SET active = 0")

    # Activate the selected one
    case Repo.query(
           "UPDATE interaction_styles SET active = 1 WHERE name = ?",
           [style_name]
         ) do
      {:ok, %{num_rows: 0}} ->
        {:error, :style_not_found}

      {:ok, _result} ->
        # Fetch the activated style
        load_style_by_name(style_name)
    end
  end

  defp load_style_by_name(name) do
    case Repo.query(
           "SELECT id, name, description, active, config FROM interaction_styles WHERE name = ?",
           [name]
         ) do
      {:ok, %{rows: [[id, n, desc, active, config_json]]}} ->
        {:ok, config} = Jason.decode(config_json)
        {:ok, %Style{id: id, name: n, description: desc, active: active, config: config}}

      _ ->
        {:error, :style_not_found}
    end
  end
end
