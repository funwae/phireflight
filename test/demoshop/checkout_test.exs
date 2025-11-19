defmodule DemoShop.CheckoutTest do
  use PhireFlight.DataCase

  alias DemoShop.{Accounts, Catalog, Checkout, Orders, Billing}
  alias PhireFlight.Instrumentation.Client
  alias PhireFlight.{Apps, Accounts as PhireFlightAccounts}

  setup do
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

    # Create products
    {:ok, product1} = %DemoShop.Catalog.Product{}
    |> DemoShop.Catalog.Product.changeset(%{
      name: "Product 1",
      price_cents: 1000,
      stock_quantity: 10,
      active: true
    })
    |> PhireFlight.Repo.insert()

    {:ok, product2} = %DemoShop.Catalog.Product{}
    |> DemoShop.Catalog.Product.changeset(%{
      name: "Product 2",
      price_cents: 2000,
      stock_quantity: 5,
      active: true
    })
    |> PhireFlight.Repo.insert()

    # Create cart with items
    session_id = UUID.uuid4()
    cart = Catalog.get_or_create_cart(session_id)
    {:ok, _item1} = Catalog.add_to_cart(cart, product1.id, 2)
    {:ok, _item2} = Catalog.add_to_cart(cart, product2.id, 1)

    # Preload cart items with products
    cart = DemoShop.Repo.preload(cart, cart_items: :product)

    # Start trace for instrumentation
    {:ok, _trace_id} = Client.start_trace(%{
      app_slug: app.slug,
      entry_point: "POST /checkout"
    })

    %{app: app, user: user, cart: cart, product1: product1, product2: product2}
  end

  describe "process_checkout_good/3" do
    test "creates order and payment successfully", %{cart: cart, user: user} do
      payment_method = "card"

      assert {:ok, order} = Checkout.process_checkout_good(cart, user, payment_method)

      assert order.user_id == user.id
      assert order.status == :confirmed
      assert order.total_cents == 4000  # (2 * 1000) + (1 * 2000)

      # Verify payment was created
      payment = Billing.get_payment_for_order(order.id)
      assert payment != nil
      assert payment.amount_cents == order.total_cents
      assert payment.status == :succeeded

      # Verify cart was cleared
      cart = DemoShop.Repo.preload(cart, :cart_items)
      assert length(cart.cart_items) == 0
    end

    test "creates order with line items", %{cart: cart, user: user, product1: product1, product2: product2} do
      {:ok, order} = Checkout.process_checkout_good(cart, user, "card")

      order = Orders.get_order(order.id)
      assert length(order.line_items) == 2

      item1 = Enum.find(order.line_items, &(&1.product_id == product1.id))
      assert item1.quantity == 2
      assert item1.price_cents == product1.price_cents

      item2 = Enum.find(order.line_items, &(&1.product_id == product2.id))
      assert item2.quantity == 1
      assert item2.price_cents == product2.price_cents
    end
  end

  describe "process_checkout_bad/3" do
    test "creates order but uses direct Repo calls", %{cart: cart, user: user} do
      payment_method = "card"

      assert {:ok, order} = Checkout.process_checkout_bad(cart, user, payment_method)

      assert order.user_id == user.id
      assert order.status == :confirmed
      assert order.total_cents == 4000

      # Verify payment was created (still uses context API)
      payment = Billing.get_payment_for_order(order.id)
      assert payment != nil
    end
  end
end

