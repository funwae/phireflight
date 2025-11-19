defmodule PhireFlightWeb.TracesLiveTest do
  use PhireFlightWeb.ConnCase

  import Phoenix.LiveViewTest

  alias PhireFlight.{Apps, Accounts, Traces, TraceEvents, Contexts}

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

    # Create context
    {:ok, context} = Contexts.create_app_context(%{
      app_id: app.id,
      name: "Accounts",
      full_name: "TestApp.Accounts",
      kind: :domain
    })

    # Create trace with events
    {:ok, trace} = Traces.start_trace(%{
      app_id: app.id,
      entry_point: "GET /test"
    })

    {:ok, _event1} = TraceEvents.record_event(%{
      trace_id: trace.id,
      module: "TestApp.Accounts",
      function: "get_user",
      arity: 1,
      app_context_id: context.id,
      event_type: :context_call
    })

    {:ok, _event2} = TraceEvents.record_event(%{
      trace_id: trace.id,
      module: "TestApp.Catalog",
      function: "list_products",
      arity: 0,
      event_type: :context_call
    })

    {:ok, _} = Traces.finish_trace(trace, :ok)

    %{conn: conn, app: app, trace: trace}
  end

  describe "Show" do
    test "displays flight details", %{conn: conn, app: app, trace: trace} do
      {:ok, _show_live, html} = live(conn, ~p"/apps/#{app.id}/traces/#{trace.id}")

      assert html =~ "Flight Replay"
      assert html =~ trace.entry_point
      assert html =~ "Context Flow"
      assert html =~ "Timeline"
    end

    test "renders context diagram container", %{conn: conn, app: app, trace: trace} do
      {:ok, _show_live, html} = live(conn, ~p"/apps/#{app.id}/traces/#{trace.id}")

      assert html =~ "Context Flow"
      # Should show context name
      assert html =~ "Accounts"
    end

    test "renders timeline entries", %{conn: conn, app: app, trace: trace} do
      {:ok, _show_live, html} = live(conn, ~p"/apps/#{app.id}/traces/#{trace.id}")

      assert html =~ "Timeline"
      assert html =~ "get_user"
      assert html =~ "list_products"
    end

    test "displays status and entry point", %{conn: conn, app: app, trace: trace} do
      {:ok, _show_live, html} = live(conn, ~p"/apps/#{app.id}/traces/#{trace.id}")

      assert html =~ trace.entry_point
      assert html =~ "OK"
    end

    test "can select event from timeline", %{conn: conn, app: app, trace: trace} do
      {:ok, show_live, _html} = live(conn, ~p"/apps/#{app.id}/traces/#{trace.id}")

      # Find and click an event
      events = TraceEvents.list_trace_events(trace.id)
      event = List.first(events)

      assert show_live
      |> element("div[phx-click='select_event'][phx-value-event_id='#{event.id}']")
      |> render_click()

      # Event should be selected (check for highlighted state)
      assert render(show_live) =~ event.function
    end
  end
end

