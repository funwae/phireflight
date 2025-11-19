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

# Example seed data (uncomment when contexts are implemented in Phase 2)

# alias PhireFlight.Repo
# alias PhireFlight.Accounts.User
# alias PhireFlight.Apps.App
# alias PhireFlight.Contexts.AppContext

# # Create a demo user
# {:ok, user} = %User{}
#   |> User.registration_changeset(%{
#     email: "demo@phireflight.dev",
#     name: "Demo User",
#     password: "demo-password-12345"
#   })
#   |> Repo.insert()

# # Create a demo app
# {:ok, app} = %App{}
#   |> App.changeset(%{
#     name: "DemoShop",
#     slug: "demoshop",
#     description: "Demo e-commerce application",
#     owner_id: user.id
#   })
#   |> Repo.insert()

# # Create demo contexts
# contexts = [
#   %{name: "Accounts", kind: :domain, color: "#3B82F6"},
#   %{name: "Catalog", kind: :domain, color: "#10B981"},
#   %{name: "Checkout", kind: :domain, color: "#F59E0B"},
#   %{name: "Orders", kind: :domain, color: "#8B5CF6"},
#   %{name: "Billing", kind: :integration, color: "#EF4444"}
# ]

# Enum.each(contexts, fn context_attrs ->
#   %AppContext{}
#   |> AppContext.changeset(Map.put(context_attrs, :app_id, app.id))
#   |> Repo.insert!()
# end)

# IO.puts("Seeds completed!")
# IO.puts("Demo user: demo@phireflight.dev / demo-password-12345")
# IO.puts("Demo app slug: demoshop")
