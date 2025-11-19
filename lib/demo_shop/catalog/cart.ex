defmodule DemoShop.Catalog.Cart do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "demo_carts" do
    field :session_id, :string
    belongs_to :user, DemoShop.Accounts.User

    has_many :cart_items, DemoShop.Catalog.CartItem

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(cart, attrs) do
    cart
    |> cast(attrs, [:session_id, :user_id])
    |> validate_required([:session_id])
  end
end

