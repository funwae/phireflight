defmodule DemoShopWeb.CheckoutControllerTest do
  use PhireFlightWeb.ConnCase

  alias DemoShop.{Accounts, Catalog}
  alias PhireFlight.{Apps, Accounts as PhireFlightAccounts}

  setup %{conn: conn} do
    # Set up PhireFlight app for instrumentation
    {:ok, pf_user} = PhireFlightAccounts.register_user(%{
      email: "pf@example.com",
      password: "password123456",
      name: "PF User"
    })

    {:ok, app} = Apps.create_app(%{
      name: "DemoShop",
      slug: "demo-shop",
      owner_id: pf_user.id
    })

    # Create DemoShop user
    {:ok, user} = Accounts.create_user(%{
      email: "demo@example.com",
      name: "Demo User",
      password: "password123456"
    })

    # Create product
    {:ok, product} = %Catalog.Product{}
    |> Catalog.Product.changeset(%{
      name: "Test Product",
      price_cents: 1000,
      stock_quantity: 10,
      active: true
    })
    |> PhireFlight.Repo.insert()

    # Create cart with item
    session_id = UUID.uuid4()
    conn = put_session(conn, :cart_session_id, session_id)
    cart = Catalog.get_or_create_cart(session_id)
    {:ok, _item} = Catalog.add_to_cart(cart, product.id, 1)

    %{conn: conn, app: app, user: user, product: product, cart: cart}
  end

  describe "show/2" do
    test "renders checkout page with cart items", %{conn: conn} do
      conn = get(conn, ~p"/demo/checkout")
      assert html_response(conn, 200) =~ "Checkout"
      assert html_response(conn, 200) =~ "Test Product"
    end

    test "shows empty cart message when cart is empty", %{conn: conn} do
      # Clear the session to get a new empty cart
      conn = delete_session(conn, :cart_session_id)
      conn = get(conn, ~p"/demo/checkout")
      assert html_response(conn, 200) =~ "Your cart is empty"
    end
  end

  describe "create/2" do
    test "creates order with good flow", %{conn: conn} do
      conn = post(conn, ~p"/demo/checkout", %{
        "payment_method" => "card",
        "use_good_flow" => "true"
      })

      assert redirected_to(conn) =~ ~r"/demo/orders/"
      assert get_flash(conn, :info) =~ "Order placed successfully"
    end

    test "creates order with bad flow", %{conn: conn} do
      conn = post(conn, ~p"/demo/checkout", %{
        "payment_method" => "card",
        "use_good_flow" => "false"
      })

      assert redirected_to(conn) =~ ~r"/demo/orders/"
      assert get_flash(conn, :info) =~ "Order placed successfully"
    end

    test "redirects with error when cart is empty", %{conn: conn} do
      # Clear the session
      conn = delete_session(conn, :cart_session_id)
      conn = post(conn, ~p"/demo/checkout", %{
        "payment_method" => "card",
        "use_good_flow" => "true"
      })

      assert redirected_to(conn) == ~p"/demo/checkout"
      assert get_flash(conn, :error) =~ "Cart is empty"
    end
  end
end

