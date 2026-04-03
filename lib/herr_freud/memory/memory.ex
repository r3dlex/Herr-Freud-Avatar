defmodule HerrFreud.Memory.Memory do
  use Ecto.Schema

  @primary_key {:id, :string, autogenerate: false}
  schema "memories" do
    field :session_id, :string
    field :content, :string
    field :embedding, :binary
    field :recency_score, :float
    field :inserted_at, :utc_datetime
  end
end
