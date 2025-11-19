defmodule PhireFlight.Apps.App do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "apps" do
    field :name, :string
    field :slug, :string
    field :api_key, :string
    field :description, :string
    field :active, :boolean, default: true

    belongs_to :owner, PhireFlight.Accounts.User
    has_many :app_contexts, PhireFlight.Contexts.AppContext
    has_many :traces, PhireFlight.Traces.Trace
    has_many :visualization_layouts, PhireFlight.Visualizations.VisualizationLayout

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(app, attrs) do
    app
    |> cast(attrs, [:name, :slug, :description, :active, :owner_id])
    |> validate_required([:name, :slug, :owner_id])
    |> validate_length(:name, min: 1, max: 100)
    |> validate_length(:slug, min: 1, max: 100)
    |> validate_format(:slug, ~r/^[a-z0-9-]+$/)
    |> unique_constraint(:slug)
    |> foreign_key_constraint(:owner_id)
    |> put_api_key()
  end

  defp put_api_key(changeset) do
    if get_field(changeset, :api_key) do
      changeset
    else
      put_change(changeset, :api_key, generate_api_key())
    end
  end

  defp generate_api_key do
    :crypto.strong_rand_bytes(32) |> Base.url_encode64(padding: false)
  end
end
