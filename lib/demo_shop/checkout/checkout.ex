defmodule DemoShop.Checkout do
  @moduledoc """
  The Checkout context - orchestrates the checkout process.
  """

  alias PhireFlight.Instrumentation.Client
  alias DemoShop.{Catalog, Orders, Billing}

  @doc """
  Processes a checkout (GOOD version - uses context APIs).
  """
  def process_checkout_good(cart, user, payment_method) do
    Client.trace_function("DemoShop.Checkout", "process_checkout_good", 3, fn ->
      with {:ok, order} <- Orders.create_order_from_cart(cart, user),
           {:ok, _payment} <- Billing.charge_order(order, payment_method),
           {:ok, order} <- Orders.confirm_order(order),
           {:ok, _cart} <- Catalog.clear_cart(cart) do
        {:ok, order}
      else
        {:error, reason} -> {:error, reason}
      end
    end)
  end

  @doc """
  Processes a checkout (BAD version - demonstrates anti-patterns).

  This version intentionally:
  1. Calls Repo directly
  2. Skips context boundaries
  3. Has tight coupling

  Used to demonstrate what PhireFlight catches!
  """
  def process_checkout_bad(cart, user, payment_method) do
    Client.trace_function("DemoShop.Checkout", "process_checkout_bad", 3, fn ->
      # BAD: Calling Repo directly instead of Orders.create_order_from_cart
      alias DemoShop.Repo
      alias DemoShop.Orders.Order

      cart = DemoShop.Repo.preload(cart, cart_items: :product)

      order_attrs = %{
        user_id: user.id,
        order_number: generate_order_number(),
        status: :pending,
        total_cents: calculate_total(cart)
      }

      # This will be flagged by AI narration!
      {:ok, order} = %Order{}
      |> Order.changeset(order_attrs)
      |> Repo.insert()

      # Still calls context API (mixed pattern)
      Billing.charge_order(order, payment_method)

      # BAD: Direct Repo update instead of Orders.confirm_order
      order
      |> Order.changeset(%{status: :confirmed})
      |> Repo.update()

      Catalog.clear_cart(cart)

      {:ok, order}
    end)
  end

  defp generate_order_number do
    "ORD-#{:rand.uniform(999999) |> Integer.to_string() |> String.pad_leading(6, "0")}"
  end

  defp calculate_total(cart) do
    cart.cart_items
    |> Enum.reduce(0, fn item, acc ->
      acc + (item.quantity * item.product.price_cents)
    end)
  end
end

