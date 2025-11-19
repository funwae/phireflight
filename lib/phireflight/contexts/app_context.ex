defmodule PhireFlight.Contexts.AppContext do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "app_contexts" do
    field :name, :string
    field :full_name, :string
    field :description, :string
    field :kind, Ecto.Enum, values: [:domain, :integration, :ui, :infra], default: :domain
    field :color, :string
    field :position, :integer

    belongs_to :app, PhireFlight.Apps.App
    has_many :trace_events, PhireFlight.TraceEvents.TraceEvent

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(app_context, attrs) do
    app_context
    |> cast(attrs, [:name, :full_name, :description, :kind, :color, :position, :app_id])
    |> validate_required([:name, :app_id])
    |> validate_length(:name, min: 1, max: 100)
    |> validate_inclusion(:kind, [:domain, :integration, :ui, :infra])
    |> validate_format(:color, ~r/^#[0-9A-Fa-f]{6}$/, message: "must be a valid hex color")
    |> unique_constraint([:app_id, :name])
    |> foreign_key_constraint(:app_id)
  end
end
