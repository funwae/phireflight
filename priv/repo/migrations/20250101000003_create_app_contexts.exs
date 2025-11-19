defmodule PhireFlight.Repo.Migrations.CreateAppContexts do
  use Ecto.Migration

  def change do
    create table(:app_contexts, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :app_id, references(:apps, type: :binary_id, on_delete: :delete_all), null: false
      add :name, :string, size: 100, null: false
      add :full_name, :string, size: 255
      add :description, :text
      add :kind, :string, size: 20, default: "domain", null: false
      add :color, :string, size: 7
      add :position, :integer

      timestamps(type: :utc_datetime)
    end

    create unique_index(:app_contexts, [:app_id, :name])
    create index(:app_contexts, [:app_id])

    create constraint(:app_contexts, :valid_kind, check: "kind IN ('domain', 'integration', 'ui', 'infra')")
  end
end
