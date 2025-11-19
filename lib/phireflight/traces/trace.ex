defmodule PhireFlight.Traces.Trace do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "traces" do
    field :external_id, :string
    field :entry_point, :string
    field :request_method, :string
    field :request_path, :string
    field :status, Ecto.Enum, values: [:ok, :error, :timeout, :cancelled], default: :ok
    field :started_at, :utc_datetime
    field :finished_at, :utc_datetime
    field :duration_ms, :integer
    field :error_class, :string
    field :error_message, :string
    field :metadata, :map

    belongs_to :app, PhireFlight.Apps.App
    has_many :trace_events, PhireFlight.TraceEvents.TraceEvent
    has_one :narration, PhireFlight.Narrations.Narration

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(trace, attrs) do
    trace
    |> cast(attrs, [
      :external_id,
      :entry_point,
      :request_method,
      :request_path,
      :status,
      :started_at,
      :finished_at,
      :duration_ms,
      :error_class,
      :error_message,
      :metadata,
      :app_id
    ])
    |> validate_required([:entry_point, :started_at, :app_id])
    |> validate_inclusion(:status, [:ok, :error, :timeout, :cancelled])
    |> foreign_key_constraint(:app_id)
  end

  @doc """
  A trace changeset for finishing a trace.
  Automatically calculates duration_ms if started_at and finished_at are present.
  """
  def finish_changeset(trace, attrs) do
    changeset(trace, attrs)
    |> put_duration()
  end

  defp put_duration(changeset) do
    started = get_field(changeset, :started_at)
    finished = get_field(changeset, :finished_at)

    if started && finished do
      duration = DateTime.diff(finished, started, :millisecond)
      put_change(changeset, :duration_ms, duration)
    else
      changeset
    end
  end
end
