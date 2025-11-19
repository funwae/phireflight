defmodule DemoShop.Billing.Payment do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "demo_payments" do
    field :amount_cents, :integer
    field :status, Ecto.Enum, values: [:pending, :succeeded, :failed], default: :pending, type: :string
    field :payment_method, :string
    field :external_id, :string

    belongs_to :order, DemoShop.Orders.Order

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(payment, attrs) do
    payment
    |> cast(attrs, [:amount_cents, :status, :payment_method, :external_id, :order_id])
    |> validate_required([:amount_cents, :status, :payment_method, :order_id])
    |> validate_number(:amount_cents, greater_than: 0)
  end
end

