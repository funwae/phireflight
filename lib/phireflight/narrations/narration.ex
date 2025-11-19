defmodule PhireFlight.Narrations.Narration do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "narrations" do
    field :model_name, :string
    field :summary, :string
    field :details, :string
    field :issues, {:array, :map}
    field :generation_time_ms, :integer

    belongs_to :trace, PhireFlight.Traces.Trace

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(narration, attrs) do
    narration
    |> cast(attrs, [:model_name, :summary, :details, :issues, :generation_time_ms, :trace_id])
    |> validate_required([:model_name, :summary, :trace_id])
    |> validate_length(:summary, max: 1000)
    |> foreign_key_constraint(:trace_id)
    |> unique_constraint(:trace_id)
  end
end
