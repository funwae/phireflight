defmodule PhireFlight.Contexts do
  @moduledoc """
  The Contexts context manages logical contexts within observed apps.
  """

  alias PhireFlight.Contexts.AppContext
  alias PhireFlight.Repo
  import Ecto.Query

  @doc """
  Returns the list of contexts for a given app.

  ## Examples

      iex> list_app_contexts(app_id)
      [%AppContext{}, ...]
  """
  @spec list_app_contexts(binary()) :: [AppContext.t()]
  def list_app_contexts(app_id) do
    Repo.all(
      from ac in AppContext,
        where: ac.app_id == ^app_id,
        order_by: [asc: ac.position, asc: ac.name]
    )
  end

  @doc """
  Gets a single app context.

  Raises `Ecto.NoResultsError` if the AppContext does not exist.
  """
  @spec get_app_context!(binary()) :: AppContext.t()
  def get_app_context!(id), do: Repo.get!(AppContext, id)

  @doc """
  Gets an app context by app_id and name.
  """
  @spec get_app_context_by_name(binary(), String.t()) :: AppContext.t() | nil
  def get_app_context_by_name(app_id, name) do
    Repo.get_by(AppContext, app_id: app_id, name: name)
  end

  @doc """
  Finds or creates an app context by name.
  Useful during trace ingestion when contexts are auto-discovered.
  """
  @spec find_or_create_app_context(binary(), String.t(), map()) ::
          {:ok, AppContext.t()} | {:error, Ecto.Changeset.t()}
  def find_or_create_app_context(app_id, name, attrs \\ %{}) do
    case get_app_context_by_name(app_id, name) do
      nil -> create_app_context(Map.merge(attrs, %{app_id: app_id, name: name}))
      context -> {:ok, context}
    end
  end

  @doc """
  Creates an app context.

  ## Examples

      iex> create_app_context(%{app_id: app_id, name: "Accounts"})
      {:ok, %AppContext{}}
  """
  @spec create_app_context(map()) :: {:ok, AppContext.t()} | {:error, Ecto.Changeset.t()}
  def create_app_context(attrs \\ %{}) do
    %AppContext{}
    |> AppContext.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates an app context.
  """
  @spec update_app_context(AppContext.t(), map()) ::
          {:ok, AppContext.t()} | {:error, Ecto.Changeset.t()}
  def update_app_context(%AppContext{} = app_context, attrs) do
    app_context
    |> AppContext.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes an app context.
  """
  @spec delete_app_context(AppContext.t()) ::
          {:ok, AppContext.t()} | {:error, Ecto.Changeset.t()}
  def delete_app_context(%AppContext{} = app_context) do
    Repo.delete(app_context)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking app context changes.
  """
  @spec change_app_context(AppContext.t(), map()) :: Ecto.Changeset.t()
  def change_app_context(%AppContext{} = app_context, attrs \\ %{}) do
    AppContext.changeset(app_context, attrs)
  end
end

