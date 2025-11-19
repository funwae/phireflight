defmodule DemoShop.Accounts do
  @moduledoc """
  The Accounts context - manages users and authentication.
  """

  alias PhireFlight.Instrumentation.Client
  alias DemoShop.Repo
  alias DemoShop.Accounts.User

  @doc """
  Gets a user by ID.
  """
  def get_user(id) do
    Client.trace_function("DemoShop.Accounts", "get_user", 1, fn ->
      Repo.get(User, id)
    end)
  end

  @doc """
  Gets a user by email.
  """
  def get_user_by_email(email) do
    Client.trace_function("DemoShop.Accounts", "get_user_by_email", 1, fn ->
      Repo.get_by(User, email: email)
    end)
  end

  @doc """
  Creates a new user.
  """
  def create_user(attrs) do
    Client.trace_function("DemoShop.Accounts", "create_user", 1, fn ->
      %User{}
      |> User.changeset(attrs)
      |> Repo.insert()
    end)
  end

  @doc """
  Lists all users (admin function).
  """
  def list_users do
    Client.trace_function("DemoShop.Accounts", "list_users", 0, fn ->
      Repo.all(User)
    end)
  end
end

