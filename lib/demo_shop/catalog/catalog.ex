defmodule DemoShop.Catalog do
  @moduledoc """
  The Catalog context - manages products and shopping carts.
  """

  alias PhireFlight.Instrumentation.Client
  alias DemoShop.Repo
  alias DemoShop.Catalog.{Product, Cart, CartItem}
  import Ecto.Query

  @doc """
  Lists active products.
  """
  def list_products do
    Client.trace_function("DemoShop.Catalog", "list_products", 0, fn ->
      Product
      |> where([p], p.active == true)
      |> order_by([p], p.name)
      |> Repo.all()
    end)
  end

  @doc """
  Gets a product by ID.
  """
  def get_product(id) do
    Client.trace_function("DemoShop.Catalog", "get_product", 1, fn ->
      Repo.get(Product, id)
    end)
  end

  @doc """
  Gets or creates a cart for a session.
  """
  def get_or_create_cart(session_id, user_id \\ nil) do
    Client.trace_function("DemoShop.Catalog", "get_or_create_cart", 2, fn ->
      case Repo.get_by(Cart, session_id: session_id) do
        nil ->
          %Cart{session_id: session_id, user_id: user_id}
          |> Cart.changeset(%{})
          |> Repo.insert!()

        cart ->
          cart
      end
      |> Repo.preload(:cart_items)
    end)
  end

  @doc """
  Adds a product to cart.
  """
  def add_to_cart(cart, product_id, quantity \\ 1) do
    Client.trace_function("DemoShop.Catalog", "add_to_cart", 3, fn ->
      cart = Repo.preload(cart, :cart_items)

      case Enum.find(cart.cart_items, &(&1.product_id == product_id)) do
        nil ->
          %CartItem{
            cart_id: cart.id,
            product_id: product_id,
            quantity: quantity
          }
          |> CartItem.changeset(%{})
          |> Repo.insert()

        item ->
          item
          |> CartItem.changeset(%{quantity: item.quantity + quantity})
          |> Repo.update()
      end
    end)
  end

  @doc """
  Clears a cart.
  """
  def clear_cart(cart) do
    Client.trace_function("DemoShop.Catalog", "clear_cart", 1, fn ->
      CartItem
      |> where([i], i.cart_id == ^cart.id)
      |> Repo.delete_all()

      {:ok, cart}
    end)
  end
end

