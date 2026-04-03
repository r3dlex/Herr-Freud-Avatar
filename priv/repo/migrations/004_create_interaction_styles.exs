defmodule HerrFreud.Repo.Migrations.CreateInteractionStyles do
  use Ecto.Migration

  def change do
    create table(:interaction_styles, primary_key: false) do
      add :id, :string, primary_key: true
      add :name, :string, null: false
      add :description, :text, null: false
      add :active, :boolean, null: false, default: false
      add :config, :text, null: false
    end

    create unique_index(:interaction_styles, [:name])
  end
end
