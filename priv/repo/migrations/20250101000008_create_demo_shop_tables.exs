defmodule PhireFlight.Repo.Migrations.CreateDemoShopTables do
  use Ecto.Migration

  def change do
    # DemoShop Users
    create table(:demo_users, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :email, :string, null: false
      add :name, :string, null: false
      add :hashed_password, :string, null: false

      timestamps(type: :utc_datetime)
    end

    create unique_index(:demo_users, [:email])

    # DemoShop Products
    create table(:demo_products, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :name, :string, null: false
      add :description, :text
      add :price_cents, :integer, null: false
      add :stock_quantity, :integer, null: false, default: 0
      add :active, :boolean, default: true, null: false

      timestamps(type: :utc_datetime)
    end

    # DemoShop Carts
    create table(:demo_carts, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :session_id, :string, null: false
      add :user_id, references(:demo_users, type: :binary_id, on_delete: :nilify_all)

      timestamps(type: :utc_datetime)
    end

    create index(:demo_carts, [:session_id])
    create index(:demo_carts, [:user_id])

    # DemoShop Cart Items
    create table(:demo_cart_items, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :quantity, :integer, null: false
      add :cart_id, references(:demo_carts, type: :binary_id, on_delete: :delete_all), null: false
      add :product_id, references(:demo_products, type: :binary_id, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime)
    end

    create index(:demo_cart_items, [:cart_id])
    create index(:demo_cart_items, [:product_id])
    create unique_index(:demo_cart_items, [:cart_id, :product_id])

    # DemoShop Orders
    create table(:demo_orders, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :order_number, :string, null: false
      add :status, :string, null: false, default: "pending"
      add :total_cents, :integer, null: false
      add :user_id, references(:demo_users, type: :binary_id, on_delete: :nilify_all), null: false

      timestamps(type: :utc_datetime)
    end

    create unique_index(:demo_orders, [:order_number])
    create index(:demo_orders, [:user_id])
    create index(:demo_orders, [:status])

    # DemoShop Line Items
    create table(:demo_line_items, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :product_name, :string, null: false
      add :quantity, :integer, null: false
      add :price_cents, :integer, null: false
      add :order_id, references(:demo_orders, type: :binary_id, on_delete: :delete_all), null: false
      add :product_id, references(:demo_products, type: :binary_id, on_delete: :nilify_all)

      timestamps(type: :utc_datetime)
    end

    create index(:demo_line_items, [:order_id])
    create index(:demo_line_items, [:product_id])

    # DemoShop Payments
    create table(:demo_payments, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :amount_cents, :integer, null: false
      add :status, :string, null: false, default: "pending"
      add :payment_method, :string, null: false
      add :external_id, :string
      add :order_id, references(:demo_orders, type: :binary_id, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime)
    end

    create unique_index(:demo_payments, [:order_id])
  end
end

