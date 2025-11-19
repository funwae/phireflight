defmodule DemoShopWeb.ProductController do
  use PhireFlightWeb, :controller

  alias DemoShop.Catalog

  def index(conn, _params) do
    products = Catalog.list_products()
    render(conn, :index, products: products)
  end

  def show(conn, %{"id" => id}) do
    case Catalog.get_product(id) do
      nil ->
        conn
        |> put_flash(:error, "Product not found")
        |> redirect(to: ~p"/demo/products")

      product ->
        render(conn, :show, product: product)
    end
  end
end

