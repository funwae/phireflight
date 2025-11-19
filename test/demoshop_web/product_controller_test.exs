defmodule DemoShopWeb.ProductControllerTest do
  use PhireFlightWeb.ConnCase

  alias DemoShop.Catalog

  setup %{conn: conn} do
    # Create test products
    {:ok, product1} = %Catalog.Product{}
    |> Catalog.Product.changeset(%{
      name: "Test Product 1",
      description: "Description 1",
      price_cents: 1000,
      stock_quantity: 10,
      active: true
    })
    |> PhireFlight.Repo.insert()

    {:ok, product2} = %Catalog.Product{}
    |> Catalog.Product.changeset(%{
      name: "Test Product 2",
      description: "Description 2",
      price_cents: 2000,
      stock_quantity: 5,
      active: false
    })
    |> PhireFlight.Repo.insert()

    %{conn: conn, product1: product1, product2: product2}
  end

  describe "index/2" do
    test "lists all active products", %{conn: conn, product1: product1} do
      conn = get(conn, ~p"/demo/products")
      assert html_response(conn, 200) =~ "DemoShop Products"
      assert html_response(conn, 200) =~ product1.name
      assert html_response(conn, 200) =~ "$10.00"
    end

    test "does not show inactive products", %{conn: conn, product2: product2} do
      conn = get(conn, ~p"/demo/products")
      html = html_response(conn, 200)
      refute html =~ product2.name
    end
  end

  describe "show/2" do
    test "renders product details", %{conn: conn, product1: product1} do
      conn = get(conn, ~p"/demo/products/#{product1.id}")
      assert html_response(conn, 200) =~ product1.name
      assert html_response(conn, 200) =~ product1.description
      assert html_response(conn, 200) =~ "$10.00"
    end

    test "redirects when product not found", %{conn: conn} do
      conn = get(conn, ~p"/demo/products/#{UUID.uuid4()}")
      assert redirected_to(conn) == ~p"/demo/products"
    end
  end
end

