# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     PhireFlight.Repo.insert!(%PhireFlight.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.

alias PhireFlight.Repo
alias PhireFlight.{Accounts, Apps, Contexts}
alias PhireFlight.Accounts.User
alias PhireFlight.Apps.App
alias PhireFlight.Contexts.AppContext

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

# Create contexts for DemoShop
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

# Create demo products for DemoShop
alias DemoShop.Catalog.Product

products = [
  %{
    name: "Phoenix Framework T-Shirt",
    description: "Show your Phoenix pride! Comfortable cotton t-shirt with Phoenix logo.",
    price_cents: 2499,
    stock_quantity: 100
  },
  %{
    name: "Elixir Mug",
    description: "Drink your morning elixir in style. High-quality ceramic mug.",
    price_cents: 1299,
    stock_quantity: 50
  },
  %{
    name: "LiveView Sticker Pack",
    description: "10 awesome LiveView stickers for your laptop",
    price_cents: 599,
    stock_quantity: 200
  },
  %{
    name: "OTP Poster",
    description: "Beautiful OTP supervision tree diagram poster",
    price_cents: 1999,
    stock_quantity: 30
  },
  %{
    name: "Erlang/OTP Book",
    description: "The definitive guide to Erlang and OTP",
    price_cents: 4999,
    stock_quantity: 25
  }
]

for product_attrs <- products do
  %Product{}
  |> Product.changeset(product_attrs)
  |> Repo.insert!()
end

IO.puts("""

✅ DemoShop seeded successfully!

PhireFlight Setup:
- User: demo@phireflight.dev / securepassword123
- App: DemoShop (slug: demo-shop)
- Contexts: Accounts, Catalog, Checkout, Orders, Billing

DemoShop Products:
- #{length(products)} products created

You can now:
1. Visit DemoShop at http://localhost:4000/demo/products
2. Browse products and add to cart
3. Checkout using either:
   - Good flow (proper context boundaries) ✓
   - Bad flow (demonstrates anti-patterns) ✗
4. View traces in PhireFlight at http://localhost:4000/apps/#{app.id}/traces
""")
