defmodule DemoShop.Orders.LineItem do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "demo_line_items" do
    field :product_name, :string
    field :quantity, :integer
    field :price_cents, :integer

    belongs_to :order, DemoShop.Orders.Order
    belongs_to :product, DemoShop.Catalog.Product

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(line_item, attrs) do
    line_item
    |> cast(attrs, [:product_name, :quantity, :price_cents, :order_id, :product_id])
    |> validate_required([:product_name, :quantity, :price_cents, :order_id, :product_id])
    |> validate_number(:quantity, greater_than: 0)
    |> validate_number(:price_cents, greater_than: 0)
  end
end

