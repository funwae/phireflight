defmodule DemoShop.Orders.Order do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "demo_orders" do
    field :order_number, :string
    field :status, Ecto.Enum, values: [:pending, :confirmed, :cancelled, :completed], default: :pending, type: :string
    field :total_cents, :integer

    belongs_to :user, DemoShop.Accounts.User
    has_many :line_items, DemoShop.Orders.LineItem
    has_one :payment, DemoShop.Billing.Payment

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(order, attrs) do
    order
    |> cast(attrs, [:order_number, :status, :total_cents, :user_id])
    |> validate_required([:order_number, :status, :total_cents, :user_id])
    |> validate_number(:total_cents, greater_than: 0)
    |> unique_constraint(:order_number)
  end
end

