defmodule DemoShop.Catalog.Product do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "demo_products" do
    field :name, :string
    field :description, :string
    field :price_cents, :integer
    field :stock_quantity, :integer
    field :active, :boolean, default: true

    has_many :cart_items, DemoShop.Catalog.CartItem
    has_many :line_items, DemoShop.Orders.LineItem

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(product, attrs) do
    product
    |> cast(attrs, [:name, :description, :price_cents, :stock_quantity, :active])
    |> validate_required([:name, :price_cents, :stock_quantity])
    |> validate_number(:price_cents, greater_than: 0)
    |> validate_number(:stock_quantity, greater_than_or_equal_to: 0)
  end
end

