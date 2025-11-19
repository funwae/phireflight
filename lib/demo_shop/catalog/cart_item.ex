defmodule DemoShop.Catalog.CartItem do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "demo_cart_items" do
    field :quantity, :integer

    belongs_to :cart, DemoShop.Catalog.Cart
    belongs_to :product, DemoShop.Catalog.Product

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(cart_item, attrs) do
    cart_item
    |> cast(attrs, [:quantity, :cart_id, :product_id])
    |> validate_required([:quantity, :cart_id, :product_id])
    |> validate_number(:quantity, greater_than: 0)
  end
end

