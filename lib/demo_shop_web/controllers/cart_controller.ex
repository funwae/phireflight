defmodule DemoShopWeb.CartController do
  use PhireFlightWeb, :controller

  alias DemoShop.Catalog

  def add(conn, %{"product_id" => product_id, "quantity" => quantity}) do
    session_id = get_session(conn, :cart_session_id) || generate_session_id()
    conn = put_session(conn, :cart_session_id, session_id)

    cart = Catalog.get_or_create_cart(session_id)
    quantity_int = String.to_integer(quantity)

    case Catalog.add_to_cart(cart, product_id, quantity_int) do
      {:ok, _cart_item} ->
        conn
        |> put_flash(:info, "Added to cart")
        |> redirect(to: ~p"/demo/products")

      {:error, _changeset} ->
        conn
        |> put_flash(:error, "Failed to add to cart")
        |> redirect(to: ~p"/demo/products")
    end
  end

  defp generate_session_id do
    UUID.uuid4()
  end
end

