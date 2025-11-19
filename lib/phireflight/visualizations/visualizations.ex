defmodule PhireFlight.Visualizations do
  @moduledoc """
  The Visualizations context manages diagram layouts.
  """

  alias PhireFlight.Visualizations.VisualizationLayout
  alias PhireFlight.Repo
  import Ecto.Query

  @doc """
  Returns the list of layouts for an app.

  ## Examples

      iex> list_layouts(app_id)
      [%VisualizationLayout{}, ...]
  """
  @spec list_layouts(binary()) :: [VisualizationLayout.t()]
  def list_layouts(app_id) do
    Repo.all(
      from vl in VisualizationLayout,
        where: vl.app_id == ^app_id,
        order_by: [desc: vl.inserted_at]
    )
  end

  @doc """
  Gets a single layout.

  Raises `Ecto.NoResultsError` if the Layout does not exist.
  """
  @spec get_layout!(binary()) :: VisualizationLayout.t()
  def get_layout!(id), do: Repo.get!(VisualizationLayout, id)

  @doc """
  Gets the default layout for an app and user.

  Falls back to app default if no user-specific layout exists.
  """
  @spec get_default_layout(binary(), binary() | nil) :: VisualizationLayout.t() | nil
  def get_default_layout(app_id, user_id \\ nil) do
    # First try to get user-specific default
    if user_id do
      case Repo.one(
             from vl in VisualizationLayout,
               where: vl.app_id == ^app_id and vl.user_id == ^user_id and vl.is_default == true,
               limit: 1
           ) do
        nil -> get_app_default_layout(app_id)
        layout -> layout
      end
    else
      get_app_default_layout(app_id)
    end
  end

  @doc """
  Creates a layout.

  ## Examples

      iex> create_layout(%{
      ...>   app_id: app_id,
      ...>   name: "My Layout",
      ...>   layout_json: %{nodes: [...]}
      ...> })
      {:ok, %VisualizationLayout{}}
  """
  @spec create_layout(map()) :: {:ok, VisualizationLayout.t()} | {:error, Ecto.Changeset.t()}
  def create_layout(attrs \\ %{}) do
    %VisualizationLayout{}
    |> VisualizationLayout.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a layout.
  """
  @spec update_layout(VisualizationLayout.t(), map()) ::
          {:ok, VisualizationLayout.t()} | {:error, Ecto.Changeset.t()}
  def update_layout(%VisualizationLayout{} = layout, attrs) do
    layout
    |> VisualizationLayout.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a layout.
  """
  @spec delete_layout(VisualizationLayout.t()) ::
          {:ok, VisualizationLayout.t()} | {:error, Ecto.Changeset.t()}
  def delete_layout(%VisualizationLayout{} = layout) do
    Repo.delete(layout)
  end

  @doc """
  Generates an automatic layout for an app's contexts.

  Uses a simple force-directed or hierarchical algorithm.
  """
  @spec generate_auto_layout(binary()) :: map()
  def generate_auto_layout(app_id) do
    alias PhireFlight.Contexts

    contexts = Contexts.list_app_contexts(app_id)

    nodes =
      contexts
      |> Enum.with_index()
      |> Enum.map(fn {context, index} ->
        # Simple grid layout
        angle = (index * 2 * :math.pi()) / max(length(contexts), 1)
        radius = 200

        %{
          "id" => context.id,
          "label" => context.name,
          "x" => trunc(radius * :math.cos(angle)),
          "y" => trunc(radius * :math.sin(angle)),
          "color" => context.color || "#3B82F6"
        }
      end)

    edges = []

    %{
      "nodes" => nodes,
      "edges" => edges,
      "metadata" => %{
        "generated_at" => DateTime.utc_now() |> DateTime.to_iso8601(),
        "algorithm" => "circular"
      }
    }
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking layout changes.
  """
  @spec change_layout(VisualizationLayout.t(), map()) :: Ecto.Changeset.t()
  def change_layout(%VisualizationLayout{} = layout, attrs \\ %{}) do
    VisualizationLayout.changeset(layout, attrs)
  end

  # Private helpers

  defp get_app_default_layout(app_id) do
    Repo.one(
      from vl in VisualizationLayout,
        where: vl.app_id == ^app_id and vl.is_default == true and is_nil(vl.user_id),
        limit: 1
    )
  end
end

