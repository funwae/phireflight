# DemoShop Example Application

## Overview
DemoShop is a simplified e-commerce Phoenix application built into PhireFlight to demonstrate context tracing. It serves as both a working example and a testing ground for the instrumentation system.

---

## Purpose

DemoShop exists to:

1. **Demonstrate instrumentation** - Show how to instrument a real Phoenix app
2. **Generate realistic traces** - Create meaningful flows for UI development
3. **Showcase architecture analysis** - Intentionally include both good and bad patterns
4. **Provide demo data** - Make PhireFlight compelling in demos/talks
5. **Test the system** - Verify instrumentation works end-to-end

---

## Domain Model

### Contexts

```
┌─────────────────────────────────────────────────────┐
│                      DemoShop                        │
├─────────────────────────────────────────────────────┤
│                                                      │
│  ┌──────────────┐  ┌──────────────┐                │
│  │   Accounts   │  │   Catalog    │                │
│  │              │  │              │                │
│  │  • Users     │  │  • Products  │                │
│  │  • Auth      │  │  • Cart      │                │
│  └──────────────┘  └──────────────┘                │
│                                                      │
│  ┌──────────────┐  ┌──────────────┐                │
│  │   Checkout   │  │    Orders    │                │
│  │              │  │              │                │
│  │  • Session   │  │  • Order     │                │
│  │  • Process   │  │  • LineItems │                │
│  └──────────────┘  └──────────────┘                │
│                                                      │
│  ┌──────────────┐                                   │
│  │   Billing    │                                   │
│  │              │                                   │
│  │  • Payments  │                                   │
│  │  • Charges   │                                   │
│  └──────────────┘                                   │
│                                                      │
└─────────────────────────────────────────────────────┘
```

### Flow Examples

**Good Flow (Checkout):**
```
Controller → Checkout.process/1
          → Orders.create_order/1
          → Billing.charge/2
          → Orders.confirm/1
```

**Bad Flow (Intentional - for demo):**
```
Controller → Checkout.process/1
          → Repo.insert (direct!) ❌
          → Billing.charge/2
             → Repo.get (direct!) ❌
```

---

## Schema Definitions

### DemoShop.Accounts.User

```elixir
defmodule DemoShop.Accounts.User do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "demo_users" do
    field :email, :string
    field :name, :string
    field :hashed_password, :string

    has_many :orders, DemoShop.Orders.Order

    timestamps(type: :utc_datetime)
  end
end
```

### DemoShop.Catalog.Product

```elixir
defmodule DemoShop.Catalog.Product do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "demo_products" do
    field :name, :string
    field :description, :string
    field :price_cents, :integer
    field :stock_quantity, :integer
    field :active, :boolean, default: true

    timestamps(type: :utc_datetime)
  end
end
```

### DemoShop.Catalog.Cart

```elixir
defmodule DemoShop.Catalog.Cart do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "demo_carts" do
    field :session_id, :string
    belongs_to :user, DemoShop.Accounts.User

    has_many :cart_items, DemoShop.Catalog.CartItem

    timestamps(type: :utc_datetime)
  end
end
```

### DemoShop.Catalog.CartItem

```elixir
defmodule DemoShop.Catalog.CartItem do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "demo_cart_items" do
    field :quantity, :integer

    belongs_to :cart, DemoShop.Catalog.Cart
    belongs_to :product, DemoShop.Catalog.Product

    timestamps(type: :utc_datetime)
  end
end
```

### DemoShop.Orders.Order

```elixir
defmodule DemoShop.Orders.Order do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "demo_orders" do
    field :order_number, :string
    field :status, Ecto.Enum, values: [:pending, :confirmed, :cancelled, :completed]
    field :total_cents, :integer

    belongs_to :user, DemoShop.Accounts.User
    has_many :line_items, DemoShop.Orders.LineItem
    has_one :payment, DemoShop.Billing.Payment

    timestamps(type: :utc_datetime)
  end
end
```

### DemoShop.Orders.LineItem

```elixir
defmodule DemoShop.Orders.LineItem do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "demo_line_items" do
    field :product_name, :string
    field :quantity, :integer
    field :price_cents, :integer

    belongs_to :order, DemoShop.Orders.Order
    belongs_to :product, DemoShop.Catalog.Product

    timestamps(type: :utc_datetime)
  end
end
```

### DemoShop.Billing.Payment

```elixir
defmodule DemoShop.Billing.Payment do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "demo_payments" do
    field :amount_cents, :integer
    field :status, Ecto.Enum, values: [:pending, :succeeded, :failed]
    field :payment_method, :string
    field :external_id, :string  # Mock Stripe ID

    belongs_to :order, DemoShop.Orders.Order

    timestamps(type: :utc_datetime)
  end
end
```

---

## Context APIs

### DemoShop.Accounts

**File:** `lib/demo_shop/accounts/accounts.ex`

```elixir
defmodule DemoShop.Accounts do
  @moduledoc """
  The Accounts context - manages users and authentication.
  """

  alias PhireFlight.Instrumentation.Client
  alias DemoShop.Repo
  alias DemoShop.Accounts.User

  @doc """
  Gets a user by ID.
  """
  def get_user(id) do
    Client.trace_function("DemoShop.Accounts", "get_user", 1, fn ->
      Repo.get(User, id)
    end)
  end

  @doc """
  Creates a new user.
  """
  def create_user(attrs) do
    Client.trace_function("DemoShop.Accounts", "create_user", 1, fn ->
      %User{}
      |> User.changeset(attrs)
      |> Repo.insert()
    end)
  end

  @doc """
  Lists all users (admin function).
  """
  def list_users do
    Client.trace_function("DemoShop.Accounts", "list_users", 0, fn ->
      Repo.all(User)
    end)
  end
end
```

### DemoShop.Catalog

**File:** `lib/demo_shop/catalog/catalog.ex`

```elixir
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
      case Repo.get_by(CartItem, cart_id: cart.id, product_id: product_id) do
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
```

### DemoShop.Checkout

**File:** `lib/demo_shop/checkout/checkout.ex`

```elixir
defmodule DemoShop.Checkout do
  @moduledoc """
  The Checkout context - orchestrates the checkout process.
  """

  alias PhireFlight.Instrumentation.Client
  alias DemoShop.{Catalog, Orders, Billing}

  @doc """
  Processes a checkout (GOOD version - uses context APIs).
  """
  def process_checkout_good(cart, user, payment_method) do
    Client.trace_function("DemoShop.Checkout", "process_checkout_good", 3, fn ->
      with {:ok, order} <- Orders.create_order_from_cart(cart, user),
           {:ok, _payment} <- Billing.charge_order(order, payment_method),
           {:ok, order} <- Orders.confirm_order(order),
           {:ok, _cart} <- Catalog.clear_cart(cart) do
        {:ok, order}
      else
        {:error, reason} -> {:error, reason}
      end
    end)
  end

  @doc """
  Processes a checkout (BAD version - demonstrates anti-patterns).

  This version intentionally:
  1. Calls Repo directly
  2. Skips context boundaries
  3. Has tight coupling

  Used to demonstrate what PhireFlight catches!
  """
  def process_checkout_bad(cart, user, payment_method) do
    Client.trace_function("DemoShop.Checkout", "process_checkout_bad", 3, fn ->
      # BAD: Calling Repo directly instead of Orders.create_order_from_cart
      alias DemoShop.Repo
      alias DemoShop.Orders.Order

      order_attrs = %{
        user_id: user.id,
        status: :pending,
        total_cents: calculate_total(cart)
      }

      # This will be flagged by AI narration!
      {:ok, order} = %Order{}
      |> Order.changeset(order_attrs)
      |> Repo.insert()

      # Still calls context API (mixed pattern)
      Billing.charge_order(order, payment_method)

      {:ok, order}
    end)
  end

  defp calculate_total(cart) do
    # Simplified calculation
    cart.cart_items
    |> Enum.reduce(0, fn item, acc ->
      acc + (item.quantity * item.product.price_cents)
    end)
  end
end
```

### DemoShop.Orders

**File:** `lib/demo_shop/orders/orders.ex`

```elixir
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
```

### DemoShop.Billing

**File:** `lib/demo_shop/billing/billing.ex`

```elixir
defmodule DemoShop.Billing do
  @moduledoc """
  The Billing context - handles payments.
  """

  alias PhireFlight.Instrumentation.Client
  alias DemoShop.Repo
  alias DemoShop.Billing.Payment

  @doc """
  Charges an order (mock Stripe integration).
  """
  def charge_order(order, payment_method) do
    Client.trace_function("DemoShop.Billing", "charge_order", 2, fn ->
      # Simulate Stripe charge
      external_id = "ch_#{:rand.uniform(999999)}"

      payment_attrs = %{
        order_id: order.id,
        amount_cents: order.total_cents,
        payment_method: payment_method,
        external_id: external_id,
        status: :succeeded  # Always succeed in demo
      }

      %Payment{}
      |> Payment.changeset(payment_attrs)
      |> Repo.insert()
    end)
  end

  @doc """
  Gets a payment for an order.
  """
  def get_payment_for_order(order_id) do
    Client.trace_function("DemoShop.Billing", "get_payment_for_order", 1, fn ->
      Repo.get_by(Payment, order_id: order_id)
    end)
  end
end
```

---

## Controllers

### DemoShopWeb.PageController

**File:** `lib/demo_shop_web/controllers/page_controller.ex`

```elixir
defmodule DemoShopWeb.PageController do
  use DemoShopWeb, :controller

  def home(conn, _params) do
    render(conn, :home, layout: false)
  end
end
```

### DemoShopWeb.ProductController

**File:** `lib/demo_shop_web/controllers/product_controller.ex`

```elixir
defmodule DemoShopWeb.ProductController do
  use DemoShopWeb, :controller

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
        |> redirect(to: ~p"/products")

      product ->
        render(conn, :show, product: product)
    end
  end
end
```

### DemoShopWeb.CheckoutController

**File:** `lib/demo_shop_web/controllers/checkout_controller.ex`

```elixir
defmodule DemoShopWeb.CheckoutController do
  use DemoShopWeb, :controller

  alias DemoShop.{Catalog, Checkout, Accounts}

  def show(conn, _params) do
    session_id = get_session(conn, :cart_session_id)
    cart = Catalog.get_or_create_cart(session_id)
    cart = DemoShop.Repo.preload(cart, cart_items: :product)

    render(conn, :show, cart: cart)
  end

  def create(conn, %{"payment_method" => payment_method, "use_good_flow" => use_good}) do
    session_id = get_session(conn, :cart_session_id)
    cart = Catalog.get_or_create_cart(session_id)
    cart = DemoShop.Repo.preload(cart, cart_items: :product)

    # Get or create demo user
    user = get_or_create_demo_user(conn)

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
        |> put_flash(:info, "Order placed successfully!")
        |> redirect(to: ~p"/orders/#{order.id}")

      {:error, _reason} ->
        conn
        |> put_flash(:error, "Checkout failed")
        |> redirect(to: ~p"/checkout")
    end
  end

  defp get_or_create_demo_user(_conn) do
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
end
```

---

## Seeds

**File:** `priv/repo/seeds.exs`

```elixir
# Create PhireFlight app and contexts for DemoShop

alias PhireFlight.{Apps, Contexts, Accounts}
alias DemoShop.Catalog

# Create a PhireFlight user
{:ok, user} = Accounts.register_user(%{
  email: "demo@phireflight.dev",
  password: "securepassword123",
  name: "Demo User"
})

# Create DemoShop app in PhireFlight
{:ok, app} = Apps.create_app(%{
  name: "DemoShop",
  slug: "demo-shop",
  description: "Example e-commerce application for demonstrating PhireFlight",
  owner_id: user.id
})

# Create contexts
contexts = [
  %{
    name: "Accounts",
    full_name: "DemoShop.Accounts",
    description: "User management and authentication",
    kind: :domain,
    color: "#3B82F6"
  },
  %{
    name: "Catalog",
    full_name: "DemoShop.Catalog",
    description: "Product catalog and shopping cart management",
    kind: :domain,
    color: "#10B981"
  },
  %{
    name: "Checkout",
    full_name: "DemoShop.Checkout",
    description: "Checkout process orchestration",
    kind: :domain,
    color: "#F59E0B"
  },
  %{
    name: "Orders",
    full_name: "DemoShop.Orders",
    description: "Order lifecycle management",
    kind: :domain,
    color: "#8B5CF6"
  },
  %{
    name: "Billing",
    full_name: "DemoShop.Billing",
    description: "Payment processing (mock Stripe)",
    kind: :integration,
    color: "#EC4899"
  }
]

for context_attrs <- contexts do
  Contexts.create_app_context(Map.put(context_attrs, :app_id, app.id))
end

# Create demo products
products = [
  %{
    name: "Phoenix Framework T-Shirt",
    description: "Show your Phoenix pride!",
    price_cents: 2499,
    stock_quantity: 100
  },
  %{
    name: "Elixir Mug",
    description: "Drink your morning elixir in style",
    price_cents: 1299,
    stock_quantity: 50
  },
  %{
    name: "LiveView Sticker Pack",
    description: "10 awesome LiveView stickers",
    price_cents: 599,
    stock_quantity: 200
  },
  %{
    name: "OTP Poster",
    description: "Beautiful OTP supervision tree diagram",
    price_cents: 1999,
    stock_quantity: 30
  }
]

for product_attrs <- products do
  {:ok, _} = %DemoShop.Catalog.Product{}
  |> DemoShop.Catalog.Product.changeset(product_attrs)
  |> DemoShop.Repo.insert()
end

IO.puts """

✅ DemoShop seeded successfully!

You can now:
1. Visit DemoShop at http://localhost:4000
2. Browse products and add to cart
3. Checkout using either:
   - Good flow (proper context boundaries)
   - Bad flow (demonstrates anti-patterns)
4. View traces in PhireFlight at http://localhost:4001/apps/#{app.id}/traces
"""
```

---

## Summary

**DemoShop Features:**

- ✅ **5 contexts** - Accounts, Catalog, Checkout, Orders, Billing
- ✅ **Fully instrumented** - Every key function traced
- ✅ **Good & bad flows** - Demonstrates both patterns
- ✅ **Realistic domain** - E-commerce everyone understands
- ✅ **Simple UI** - Just enough to generate traces
- ✅ **Seed data** - Pre-populated products
- ✅ **Auto-registered** - PhireFlight app + contexts created

**Demo Scenarios:**

1. **Browse Products** - Simple Catalog flow
2. **Add to Cart** - Catalog context usage
3. **Checkout (Good)** - Proper layered architecture
4. **Checkout (Bad)** - Anti-patterns for AI to detect
5. **View Order** - Orders context retrieval

**Trace Patterns to Show:**

- ✅ Clean context boundaries (good checkout)
- ❌ Direct Repo access (bad checkout)
- ❌ Context leakage
- ✅ Proper error handling
- ✅ Transaction patterns
