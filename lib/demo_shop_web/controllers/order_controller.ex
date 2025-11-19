defmodule DemoShopWeb.OrderController do
  use PhireFlightWeb, :controller

  alias DemoShop.Orders

  def show(conn, %{"id" => id}) do
    case Orders.get_order(id) do
      nil ->
        conn
        |> put_flash(:error, "Order not found")
        |> redirect(to: ~p"/demo/products")

      order ->
        render(conn, :show, order: order)
    end
  end
end

