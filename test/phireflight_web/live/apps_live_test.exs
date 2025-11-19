defmodule PhireFlightWeb.AppsLiveTest do
  use PhireFlightWeb.ConnCase

  import Phoenix.LiveViewTest

  alias PhireFlight.{Apps, Accounts, Contexts, Traces}

  setup %{conn: conn} do
    {:ok, user} = Accounts.register_user(%{
      email: "test@example.com",
      password: "password123456",
      name: "Test User"
    })

    {:ok, app} = Apps.create_app(%{
      name: "Test App",
      slug: "test-app",
      owner_id: user.id
    })

    # Create a context
    {:ok, _context} = Contexts.create_app_context(%{
      app_id: app.id,
      name: "Accounts",
      full_name: "TestApp.Accounts",
      kind: :domain
    })

    # Create a trace
    {:ok, trace} = Traces.start_trace(%{
      app_id: app.id,
      entry_point: "GET /test"
    })
    {:ok, _} = Traces.finish_trace(trace, :ok)

    %{conn: conn, app: app, user: user}
  end

  describe "Index" do
    test "lists all apps", %{conn: conn, app: app} do
      {:ok, _index_live, html} = live(conn, ~p"/apps")

      assert html =~ "Apps"
      assert html =~ app.name
      assert html =~ app.slug
    end

    test "shows app stats", %{conn: conn, app: app} do
      {:ok, _index_live, html} = live(conn, ~p"/apps")

      # Should show context count
      assert html =~ "1"  # At least one context
    end

    test "can navigate to app show page", %{conn: conn, app: app} do
      {:ok, index_live, _html} = live(conn, ~p"/apps")

      assert index_live
      |> element("a", "View")
      |> render_click() =~ app.name
    end
  end

  describe "Show" do
    test "displays app details", %{conn: conn, app: app} do
      {:ok, _show_live, html} = live(conn, ~p"/apps/#{app.id}")

      assert html =~ app.name
      assert html =~ "Context Map"
      assert html =~ "Recent Flights"
    end

    test "lists recent flights", %{conn: conn, app: app} do
      {:ok, _show_live, html} = live(conn, ~p"/apps/#{app.id}")

      assert html =~ "GET /test"
      assert html =~ "OK"
    end

    test "shows context count in stats", %{conn: conn, app: app} do
      {:ok, _show_live, html} = live(conn, ~p"/apps/#{app.id}")

      assert html =~ "Contexts"
      assert html =~ "1"  # One context
    end

    test "can navigate to flight detail", %{conn: conn, app: app} do
      {:ok, trace} = Traces.start_trace(%{
        app_id: app.id,
        entry_point: "GET /test2"
      })
      {:ok, _} = Traces.finish_trace(trace, :ok)

      {:ok, show_live, _html} = live(conn, ~p"/apps/#{app.id}")

      assert show_live
      |> element("a", "View Flight")
      |> render_click() =~ "Flight"
    end
  end
end

