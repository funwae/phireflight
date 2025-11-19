defmodule DemoShop.CatalogTest do
  use PhireFlight.DataCase

  alias DemoShop.Catalog
  alias DemoShop.Catalog.{Product, Cart, CartItem}

  setup do
    # Create test products
    {:ok, product1} = %Product{}
    |> Product.changeset(%{
      name: "Test Product 1",
      description: "Description 1",
      price_cents: 1000,
      stock_quantity: 10,
      active: true
    })
    |> PhireFlight.Repo.insert()

    {:ok, product2} = %Product{}
    |> Product.changeset(%{
      name: "Test Product 2",
      description: "Description 2",
      price_cents: 2000,
      stock_quantity: 5,
      active: true
    })
    |> PhireFlight.Repo.insert()

    %{product1: product1, product2: product2}
  end

  describe "list_products/0" do
    test "returns only active products", %{product1: product1, product2: product2} do
      # Create inactive product
      {:ok, _inactive} = %Product{}
      |> Product.changeset(%{
        name: "Inactive Product",
        price_cents: 500,
        stock_quantity: 1,
        active: false
      })
      |> PhireFlight.Repo.insert()

      products = Catalog.list_products()
      assert length(products) == 2
      assert Enum.any?(products, &(&1.id == product1.id))
      assert Enum.any?(products, &(&1.id == product2.id))
    end

    test "orders products by name", %{product1: product1, product2: product2} do
      products = Catalog.list_products()
      names = Enum.map(products, & &1.name)
      assert names == Enum.sort(names)
    end
  end

  describe "get_product/1" do
    test "returns product when found", %{product1: product1} do
      assert Catalog.get_product(product1.id) == product1
    end

    test "returns nil when not found" do
      assert Catalog.get_product(UUID.uuid4()) == nil
    end
  end

  describe "get_or_create_cart/2" do
    test "creates new cart when none exists" do
      session_id = UUID.uuid4()
      cart = Catalog.get_or_create_cart(session_id)

      assert %Cart{} = cart
      assert cart.session_id == session_id
      assert cart.user_id == nil
    end

    test "returns existing cart when found" do
      session_id = UUID.uuid4()
      cart1 = Catalog.get_or_create_cart(session_id)
      cart2 = Catalog.get_or_create_cart(session_id)

      assert cart1.id == cart2.id
    end

    test "associates cart with user when user_id provided" do
      {:ok, user} = DemoShop.Accounts.create_user(%{
        email: "user@example.com",
        name: "User",
        password: "password123456"
      })

      session_id = UUID.uuid4()
      cart = Catalog.get_or_create_cart(session_id, user.id)

      assert cart.user_id == user.id
    end

    test "preloads cart_items" do
      session_id = UUID.uuid4()
      cart = Catalog.get_or_create_cart(session_id)
      assert Ecto.assoc_loaded?(cart.cart_items)
    end
  end

  describe "add_to_cart/3" do
    test "creates new cart item when product not in cart", %{product1: product1} do
      session_id = UUID.uuid4()
      cart = Catalog.get_or_create_cart(session_id)

      assert {:ok, %CartItem{} = item} = Catalog.add_to_cart(cart, product1.id, 2)
      assert item.quantity == 2
      assert item.product_id == product1.id
      assert item.cart_id == cart.id
    end

    test "updates quantity when product already in cart", %{product1: product1} do
      session_id = UUID.uuid4()
      cart = Catalog.get_or_create_cart(session_id)

      {:ok, _item1} = Catalog.add_to_cart(cart, product1.id, 2)
      assert {:ok, %CartItem{} = item2} = Catalog.add_to_cart(cart, product1.id, 3)

      assert item2.quantity == 5
    end

    test "returns error with invalid product_id" do
      session_id = UUID.uuid4()
      cart = Catalog.get_or_create_cart(session_id)

      assert {:error, %Ecto.Changeset{}} = Catalog.add_to_cart(cart, UUID.uuid4(), 1)
    end
  end

  describe "clear_cart/1" do
    test "removes all items from cart", %{product1: product1, product2: product2} do
      session_id = UUID.uuid4()
      cart = Catalog.get_or_create_cart(session_id)

      {:ok, _item1} = Catalog.add_to_cart(cart, product1.id, 1)
      {:ok, _item2} = Catalog.add_to_cart(cart, product2.id, 2)

      assert {:ok, cart} = Catalog.clear_cart(cart)

      cart = DemoShop.Repo.preload(cart, :cart_items)
      assert length(cart.cart_items) == 0
    end
  end
end

