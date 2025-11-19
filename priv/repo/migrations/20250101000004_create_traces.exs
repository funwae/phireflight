defmodule PhireFlight.Repo.Migrations.CreateTraces do
  use Ecto.Migration

  def change do
    create table(:traces, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :app_id, references(:apps, type: :binary_id, on_delete: :delete_all), null: false
      add :external_id, :string, size: 255
      add :entry_point, :string, size: 500, null: false
      add :request_method, :string, size: 10
      add :request_path, :string, size: 500
      add :status, :string, size: 20, default: "ok", null: false
      add :started_at, :utc_datetime, null: false
      add :finished_at, :utc_datetime
      add :duration_ms, :integer
      add :error_class, :string, size: 255
      add :error_message, :text
      add :metadata, :map

      timestamps(type: :utc_datetime)
    end

    create index(:traces, [:app_id])
    create index(:traces, [:started_at])
    create index(:traces, [:status])
    create index(:traces, [:external_id])

    create constraint(:traces, :valid_status, check: "status IN ('ok', 'error', 'timeout', 'cancelled')")
  end
end
