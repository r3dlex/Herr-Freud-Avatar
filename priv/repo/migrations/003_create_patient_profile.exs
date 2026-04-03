defmodule HerrFreud.Repo.Migrations.CreatePatientProfile do
  use Ecto.Migration

  def change do
    create table(:patient_profile, primary_key: false) do
      add :key, :string, primary_key: true
      add :value, :text, null: false
      add :updated_at, :utc_datetime, null: false
    end
  end
end
