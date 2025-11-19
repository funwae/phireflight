defmodule PhireFlight.Repo.Migrations.CreateVisualizationLayouts do
  use Ecto.Migration

  def change do
    create table(:visualization_layouts, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :app_id, references(:apps, type: :binary_id, on_delete: :delete_all), null: false
      add :user_id, references(:users, type: :binary_id, on_delete: :delete_all)
      add :name, :string, size: 100, null: false
      add :layout_json, :map, null: false
      add :is_default, :boolean, default: false, null: false

      timestamps(type: :utc_datetime)
    end

    create index(:visualization_layouts, [:app_id])
    create index(:visualization_layouts, [:user_id])
  end
end
