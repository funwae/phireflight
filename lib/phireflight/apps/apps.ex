defmodule PhireFlight.Apps do
  @moduledoc """
  The Apps context manages observed Phoenix applications.
  """

  alias PhireFlight.Apps.App
  alias PhireFlight.Repo
  import Ecto.Query

  @doc """
  Returns the list of apps for a given user.

  ## Examples

      iex> list_apps(user_id)
      [%App{}, ...]
  """
  @spec list_apps(binary()) :: [App.t()]
  def list_apps(owner_id) do
    Repo.all(from a in App, where: a.owner_id == ^owner_id, order_by: [desc: a.inserted_at])
  end

  @doc """
  Returns all apps (admin function).
  """
  @spec list_all_apps() :: [App.t()]
  def list_all_apps do
    Repo.all(from a in App, order_by: [desc: a.inserted_at])
  end

  @doc """
  Gets a single app.

  Raises `Ecto.NoResultsError` if the App does not exist.
  """
  @spec get_app!(binary()) :: App.t()
  def get_app!(id), do: Repo.get!(App, id)

  @doc """
  Gets an app by slug.
  """
  @spec get_app_by_slug(String.t()) :: App.t() | nil
  def get_app_by_slug(slug) do
    Repo.get_by(App, slug: slug)
  end

  @doc """
  Gets an app by API key (for instrumentation authentication).
  """
  @spec get_app_by_api_key(String.t()) :: App.t() | nil
  def get_app_by_api_key(api_key) do
    Repo.get_by(App, api_key: api_key, active: true)
  end

  @doc """
  Creates an app.

  ## Examples

      iex> create_app(%{name: "MyApp", slug: "myapp", owner_id: user_id})
      {:ok, %App{}}

      iex> create_app(%{name: nil})
      {:error, %Ecto.Changeset{}}
  """
  @spec create_app(map()) :: {:ok, App.t()} | {:error, Ecto.Changeset.t()}
  def create_app(attrs \\ %{}) do
    %App{}
    |> App.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates an app.
  """
  @spec update_app(App.t(), map()) :: {:ok, App.t()} | {:error, Ecto.Changeset.t()}
  def update_app(%App{} = app, attrs) do
    app
    |> App.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes an app.
  """
  @spec delete_app(App.t()) :: {:ok, App.t()} | {:error, Ecto.Changeset.t()}
  def delete_app(%App{} = app) do
    Repo.delete(app)
  end

  @doc """
  Regenerates the API key for an app.
  """
  @spec regenerate_api_key(App.t()) :: {:ok, App.t()} | {:error, Ecto.Changeset.t()}
  def regenerate_api_key(%App{} = app) do
    new_api_key = :crypto.strong_rand_bytes(32) |> Base.url_encode64(padding: false)

    app
    |> change_app(%{api_key: new_api_key})
    |> Repo.update()
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking app changes.
  """
  @spec change_app(App.t(), map()) :: Ecto.Changeset.t()
  def change_app(%App{} = app, attrs \\ %{}) do
    App.changeset(app, attrs)
  end
end

