defmodule DemoShop.Orders do
  @moduledoc """
  The Orders context - manages order lifecycle.
  """

  alias PhireFlight.Instrumentation.Client
  alias DemoShop.Repo
  alias DemoShop.Orders.{Order, LineItem}
  alias DemoShop.Catalog

  @doc """
  Creates an order from a cart.
  """
  def create_order_from_cart(cart, user) do
    Client.trace_function("DemoShop.Orders", "create_order_from_cart", 2, fn ->
      cart = Repo.preload(cart, cart_items: :product)

      order_attrs = %{
        user_id: user.id,
        order_number: generate_order_number(),
        status: :pending,
        total_cents: calculate_total(cart)
      }

      line_items_attrs =
        Enum.map(cart.cart_items, fn item ->
          %{
            product_id: item.product_id,
            product_name: item.product.name,
            quantity: item.quantity,
            price_cents: item.product.price_cents
          }
        end)

      order_changeset =
        %Order{}
        |> Order.changeset(order_attrs)
        |> Ecto.Changeset.put_assoc(:line_items, build_line_items(line_items_attrs))

      Repo.insert(order_changeset)
    end)
  end

  @doc """
  Confirms an order.
  """
  def confirm_order(order) do
    Client.trace_function("DemoShop.Orders", "confirm_order", 1, fn ->
      order
      |> Order.changeset(%{status: :confirmed})
      |> Repo.update()
    end)
  end

  @doc """
  Gets an order by ID.
  """
  def get_order(id) do
    Client.trace_function("DemoShop.Orders", "get_order", 1, fn ->
      Repo.get(Order, id)
      |> Repo.preload([:line_items, :payment])
    end)
  end

  defp generate_order_number do
    "ORD-#{:rand.uniform(999999) |> Integer.to_string() |> String.pad_leading(6, "0")}"
  end

  defp calculate_total(cart) do
    Enum.reduce(cart.cart_items, 0, fn item, acc ->
      acc + (item.quantity * item.product.price_cents)
    end)
  end

  defp build_line_items(attrs_list) do
    Enum.map(attrs_list, fn attrs ->
      %LineItem{}
      |> LineItem.changeset(attrs)
    end)
  end
end

