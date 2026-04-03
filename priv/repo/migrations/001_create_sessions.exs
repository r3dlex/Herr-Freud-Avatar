defmodule HerrFreud.Repo.Migrations.CreateSessions do
  use Ecto.Migration

  def change do
    create table(:sessions, primary_key: false) do
      add :id, :string, primary_key: true
      add :inserted_at, :utc_datetime, null: false
      add :date, :date, null: false
      add :input_mode, :string, null: false
      add :source_lang, :string, null: false
      add :raw_transcript, :text
      add :english_transcript, :text, null: false
      add :response, :text, null: false
      add :style_used, :string, null: false
      add :embedding, :binary
    end

    create index(:sessions, [:date])
    create index(:sessions, [:inserted_at])
  end
end
