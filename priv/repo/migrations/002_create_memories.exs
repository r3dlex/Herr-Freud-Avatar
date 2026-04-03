defmodule HerrFreud.Repo.Migrations.CreateMemories do
  use Ecto.Migration

  def change do
    create table(:memories, primary_key: false) do
      add :id, :string, primary_key: true
      add :session_id, references(:sessions, type: :string, column: :id, on_delete: :delete_all), null: false
      add :content, :text, null: false
      add :embedding, :binary, null: false
      add :recency_score, :float, null: false
      add :inserted_at, :utc_datetime, null: false
    end

    create index(:memories, [:session_id])
    create index(:memories, [:recency_score])
  end
end
