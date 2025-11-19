defmodule PhireFlight.Repo.Migrations.CreateNarrations do
  use Ecto.Migration

  def change do
    create table(:narrations, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :trace_id, references(:traces, type: :binary_id, on_delete: :delete_all), null: false
      add :model_name, :string, size: 100, null: false
      add :summary, :string, size: 1000, null: false
      add :details, :text
      add :issues, {:array, :map}
      add :generation_time_ms, :integer

      timestamps(type: :utc_datetime)
    end

    create unique_index(:narrations, [:trace_id])
  end
end
