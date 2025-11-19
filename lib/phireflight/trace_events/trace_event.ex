defmodule PhireFlight.TraceEvents.TraceEvent do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "trace_events" do
    field :module, :string
    field :function, :string
    field :arity, :integer
    field :event_type, Ecto.Enum,
      values: [:context_call, :db_query, :external_call, :controller, :liveview, :job, :other],
      default: :other
    field :sequence_index, :integer
    field :started_at, :utc_datetime
    field :finished_at, :utc_datetime
    field :duration_ms, :integer
    field :metadata, :map
    field :error, :boolean, default: false
    field :error_message, :string

    belongs_to :trace, PhireFlight.Traces.Trace
    belongs_to :app_context, PhireFlight.Contexts.AppContext

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(trace_event, attrs) do
    trace_event
    |> cast(attrs, [
      :module,
      :function,
      :arity,
      :event_type,
      :sequence_index,
      :started_at,
      :finished_at,
      :duration_ms,
      :metadata,
      :error,
      :error_message,
      :trace_id,
      :app_context_id
    ])
    |> validate_required([:module, :function, :event_type, :sequence_index, :started_at, :trace_id])
    |> validate_number(:arity, greater_than_or_equal_to: 0)
    |> validate_number(:sequence_index, greater_than_or_equal_to: 0)
    |> validate_inclusion(:event_type, [:context_call, :db_query, :external_call, :controller, :liveview, :job, :other])
    |> foreign_key_constraint(:trace_id)
    |> foreign_key_constraint(:app_context_id)
  end
end
