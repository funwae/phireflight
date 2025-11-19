defmodule PhireFlight.Repo.Migrations.CreateTraceEvents do
  use Ecto.Migration

  def change do
    create table(:trace_events, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :trace_id, references(:traces, type: :binary_id, on_delete: :delete_all), null: false
      add :app_context_id, references(:app_contexts, type: :binary_id, on_delete: :nilify_all)
      add :module, :string, size: 255, null: false
      add :function, :string, size: 255, null: false
      add :arity, :integer
      add :event_type, :string, size: 30, default: "other", null: false
      add :sequence_index, :integer, null: false
      add :started_at, :utc_datetime, null: false
      add :finished_at, :utc_datetime
      add :duration_ms, :integer
      add :metadata, :map
      add :error, :boolean, default: false, null: false
      add :error_message, :text

      timestamps(type: :utc_datetime)
    end

    create index(:trace_events, [:trace_id])
    create index(:trace_events, [:app_context_id])
    create index(:trace_events, [:trace_id, :sequence_index])
    create index(:trace_events, [:module])
  end
end
