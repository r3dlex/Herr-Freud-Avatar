defmodule HerrFreud.InteractionStyle do
  use Ecto.Schema

  @primary_key {:id, :string, autogenerate: false}
  schema "interaction_styles" do
    field :name, :string
    field :description, :string
    field :active, :boolean
    field :config, :string
  end
end
