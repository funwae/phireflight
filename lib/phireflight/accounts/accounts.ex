defmodule PhireFlight.Accounts do
  @moduledoc """
  The Accounts context manages users and authentication.

  Note: Full authentication with UserToken will be implemented when
  phx.gen.auth is run. This provides basic user management.
  """

  alias PhireFlight.Accounts.User
  alias PhireFlight.Repo
  import Ecto.Query

  ## User registration

  @doc """
  Registers a new user.

  ## Examples

      iex> register_user(%{email: "user@example.com", password: "validpassword123"})
      {:ok, %User{}}

      iex> register_user(%{email: "invalid", password: "short"})
      {:error, %Ecto.Changeset{}}
  """
  @spec register_user(map()) :: {:ok, User.t()} | {:error, Ecto.Changeset.t()}
  def register_user(attrs) do
    %User{}
    |> User.registration_changeset(attrs)
    |> Repo.insert()
  end

  ## User retrieval

  @doc """
  Gets a single user by ID.

  Raises `Ecto.NoResultsError` if the User does not exist.
  """
  @spec get_user!(binary()) :: User.t()
  def get_user!(id), do: Repo.get!(User, id)

  @doc """
  Gets a user by email.
  """
  @spec get_user_by_email(String.t()) :: User.t() | nil
  def get_user_by_email(email) when is_binary(email) do
    Repo.get_by(User, email: email)
  end

  @doc """
  Gets a user by email and password.
  """
  @spec get_user_by_email_and_password(String.t(), String.t()) ::
          {:ok, User.t()} | {:error, :unauthorized}
  def get_user_by_email_and_password(email, password)
      when is_binary(email) and is_binary(password) do
    user = Repo.get_by(User, email: email)

    cond do
      user && User.valid_password?(user, password) ->
        {:ok, user}

      user ->
        {:error, :invalid_password}

      true ->
        Bcrypt.no_user_verify()
        {:error, :not_found}
    end
  end

  ## User updates

  @doc """
  Updates a user's profile.
  """
  @spec update_user(User.t(), map()) :: {:ok, User.t()} | {:error, Ecto.Changeset.t()}
  def update_user(%User{} = user, attrs) do
    user
    |> User.email_changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Updates a user's password.
  """
  @spec update_user_password(User.t(), String.t(), map()) ::
          {:ok, User.t()} | {:error, Ecto.Changeset.t()}
  def update_user_password(%User{} = user, password, attrs) do
    changeset =
      user
      |> User.password_changeset(attrs)
      |> User.validate_current_password(password)

    Ecto.Multi.new()
    |> Ecto.Multi.update(:user, changeset)
    |> Repo.transaction()
    |> case do
      {:ok, %{user: user}} -> {:ok, user}
      {:error, :user, changeset, _} -> {:error, changeset}
    end
  end

  ## Session tokens

  @doc """
  Generates a session token for a user.

  Note: This is a simplified implementation. Full token management
  will be available when phx.gen.auth is run and UserToken schema exists.
  """
  @spec generate_user_session_token(User.t()) :: String.t()
  def generate_user_session_token(user) do
    # Simple token generation - will be replaced with proper UserToken
    # when authentication is fully set up
    token = :crypto.strong_rand_bytes(32) |> Base.url_encode64(padding: false)
    # In a real implementation, this would be stored in user_tokens table
    token
  end

  @doc """
  Gets the user with the given signed token.

  Note: This is a placeholder. Full implementation requires UserToken schema.
  """
  @spec get_user_by_session_token(String.t()) :: User.t() | nil
  def get_user_by_session_token(_token) do
    # Placeholder - full implementation requires UserToken schema
    # This will be implemented when phx.gen.auth is run
    nil
  end

  @doc """
  Deletes a session token.

  Note: This is a placeholder. Full implementation requires UserToken schema.
  """
  @spec delete_user_session_token(String.t()) :: :ok
  def delete_user_session_token(_token) do
    # Placeholder - full implementation requires UserToken schema
    :ok
  end
end

