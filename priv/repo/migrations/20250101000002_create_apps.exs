defmodule PhireFlight.Repo.Migrations.CreateApps do
  use Ecto.Migration

  def change do
    create table(:apps, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :name, :string, size: 100, null: false
      add :slug, :string, size: 100, null: false
      add :api_key, :string, size: 64, null: false
      add :description, :text
      add :active, :boolean, default: true, null: false
      add :owner_id, references(:users, type: :binary_id, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime)
    end

    create unique_index(:apps, [:slug])
    create index(:apps, [:owner_id])
    create unique_index(:apps, [:api_key])
  end
end
