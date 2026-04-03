defmodule HerrFreud.Repo.Migrations.CreateNudges do
  use Ecto.Migration

  def change do
    create table(:nudges, primary_key: false) do
      add :id, :string, primary_key: true
      add :sent_at, :utc_datetime, null: false
      add :trigger, :string, null: false
    end

    create index(:nudges, [:sent_at])
  end
end
