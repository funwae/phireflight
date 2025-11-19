defmodule PhireFlight.Visualizations.VisualizationLayout do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "visualization_layouts" do
    field :name, :string
    field :layout_json, :map
    field :is_default, :boolean, default: false

    belongs_to :app, PhireFlight.Apps.App
    belongs_to :user, PhireFlight.Accounts.User

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(layout, attrs) do
    layout
    |> cast(attrs, [:name, :layout_json, :is_default, :app_id, :user_id])
    |> validate_required([:name, :layout_json, :app_id])
    |> validate_layout_structure()
    |> foreign_key_constraint(:app_id)
    |> foreign_key_constraint(:user_id)
  end

  defp validate_layout_structure(changeset) do
    # Validate JSON structure has required keys
    case get_change(changeset, :layout_json) do
      %{"nodes" => _nodes} = _layout ->
        changeset

      _ ->
        add_error(changeset, :layout_json, "must contain 'nodes' key")
    end
  end
end
