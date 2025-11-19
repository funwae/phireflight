defmodule DemoShopWeb.CheckoutController do
  use PhireFlightWeb, :controller

  alias DemoShop.{Catalog, Checkout, Accounts}

  def show(conn, _params) do
    session_id = get_session(conn, :cart_session_id) || generate_session_id()
    conn = put_session(conn, :cart_session_id, session_id)

    cart = Catalog.get_or_create_cart(session_id)
    cart = DemoShop.Repo.preload(cart, cart_items: :product)

    render(conn, :show, cart: cart)
  end

  def create(conn, %{"payment_method" => payment_method, "use_good_flow" => use_good}) do
    session_id = get_session(conn, :cart_session_id) || generate_session_id()
    conn = put_session(conn, :cart_session_id, session_id)

    cart = Catalog.get_or_create_cart(session_id)
    cart = DemoShop.Repo.preload(cart, cart_items: :product)

    if length(cart.cart_items) == 0 do
      conn
      |> put_flash(:error, "Cart is empty")
      |> redirect(to: ~p"/demo/checkout")
    else
      # Get or create demo user
      user = get_or_create_demo_user()

      # Use good or bad checkout flow based on param
      result =
        if use_good == "true" do
          Checkout.process_checkout_good(cart, user, payment_method)
        else
          Checkout.process_checkout_bad(cart, user, payment_method)
        end

      case result do
        {:ok, order} ->
          conn
          |> put_flash(:info, "Order placed successfully! Order #: #{order.order_number}")
          |> redirect(to: ~p"/demo/orders/#{order.id}")

        {:error, reason} ->
          conn
          |> put_flash(:error, "Checkout failed: #{inspect(reason)}")
          |> redirect(to: ~p"/demo/checkout")
      end
    end
  end

  defp get_or_create_demo_user do
    # For demo purposes, use a fixed test user
    case Accounts.get_user_by_email("demo@example.com") do
      nil ->
        {:ok, user} = Accounts.create_user(%{
          email: "demo@example.com",
          name: "Demo User",
          password: "demopassword123"
        })
        user

      user ->
        user
    end
  end

  defp generate_session_id do
    UUID.uuid4()
  end
end

