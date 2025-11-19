defmodule DemoShop.AccountsTest do
  use PhireFlight.DataCase

  alias DemoShop.Accounts
  alias DemoShop.Accounts.User

  describe "get_user/1" do
    test "returns user when found" do
      {:ok, user} = Accounts.create_user(%{
        email: "test@example.com",
        name: "Test User",
        password: "password123456"
      })

      assert Accounts.get_user(user.id) == user
    end

    test "returns nil when not found" do
      assert Accounts.get_user(UUID.uuid4()) == nil
    end
  end

  describe "get_user_by_email/1" do
    test "returns user when found" do
      {:ok, user} = Accounts.create_user(%{
        email: "test@example.com",
        name: "Test User",
        password: "password123456"
      })

      assert Accounts.get_user_by_email("test@example.com") == user
    end

    test "returns nil when not found" do
      assert Accounts.get_user_by_email("nonexistent@example.com") == nil
    end
  end

  describe "create_user/1" do
    test "creates user with valid attributes" do
      attrs = %{
        email: "newuser@example.com",
        name: "New User",
        password: "password123456"
      }

      assert {:ok, %User{} = user} = Accounts.create_user(attrs)
      assert user.email == "newuser@example.com"
      assert user.name == "New User"
      assert user.hashed_password != nil
      assert user.hashed_password != attrs.password
    end

    test "returns error with invalid attributes" do
      attrs = %{
        email: "invalid",
        name: "",
        password: "short"
      }

      assert {:error, %Ecto.Changeset{}} = Accounts.create_user(attrs)
    end

    test "enforces unique email" do
      {:ok, _user} = Accounts.create_user(%{
        email: "duplicate@example.com",
        name: "User 1",
        password: "password123456"
      })

      assert {:error, %Ecto.Changeset{errors: errors}} = Accounts.create_user(%{
        email: "duplicate@example.com",
        name: "User 2",
        password: "password123456"
      })

      assert {:email, _} = List.keyfind(errors, :email, 0)
    end
  end

  describe "list_users/0" do
    test "returns all users" do
      {:ok, user1} = Accounts.create_user(%{
        email: "user1@example.com",
        name: "User 1",
        password: "password123456"
      })

      {:ok, user2} = Accounts.create_user(%{
        email: "user2@example.com",
        name: "User 2",
        password: "password123456"
      })

      users = Accounts.list_users()
      assert length(users) == 2
      assert Enum.any?(users, &(&1.id == user1.id))
      assert Enum.any?(users, &(&1.id == user2.id))
    end

    test "returns empty list when no users" do
      assert Accounts.list_users() == []
    end
  end
end

