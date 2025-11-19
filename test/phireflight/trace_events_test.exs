defmodule PhireFlight.TraceEventsTest do
  use PhireFlight.DataCase

  alias PhireFlight.{Traces, TraceEvents, Apps, Accounts}

  setup do
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

    {:ok, trace} = Traces.start_trace(%{
      app_id: app.id,
      entry_point: "GET /test"
    })

    %{app: app, trace: trace}
  end

  describe "record_event/1" do
    test "creates event with correct sequence_index", %{trace: trace} do
      attrs1 = %{
        trace_id: trace.id,
        module: "TestApp.Accounts",
        function: "get_user",
        arity: 1,
        event_type: :context_call
      }

      assert {:ok, event1} = TraceEvents.record_event(attrs1)
      assert event1.sequence_index == 0

      attrs2 = %{
        trace_id: trace.id,
        module: "TestApp.Catalog",
        function: "list_products",
        arity: 0,
        event_type: :context_call
      }

      assert {:ok, event2} = TraceEvents.record_event(attrs2)
      assert event2.sequence_index == 1
    end

    test "records duration when provided", %{trace: trace} do
      attrs = %{
        trace_id: trace.id,
        module: "TestApp",
        function: "test_fn",
        arity: 0,
        duration_ms: 42
      }

      assert {:ok, event} = TraceEvents.record_event(attrs)
      assert event.duration_ms == 42
    end

    test "records error information", %{trace: trace} do
      attrs = %{
        trace_id: trace.id,
        module: "TestApp",
        function: "test_fn",
        arity: 0,
        error: true,
        error_class: "RuntimeError",
        error_message: "Test error"
      }

      assert {:ok, event} = TraceEvents.record_event(attrs)
      assert event.error == true
      assert event.error_class == "RuntimeError"
      assert event.error_message == "Test error"
    end

    test "returns error with invalid trace_id" do
      attrs = %{
        trace_id: UUID.uuid4(),
        module: "TestApp",
        function: "test_fn",
        arity: 0
      }

      assert {:error, %Ecto.Changeset{}} = TraceEvents.record_event(attrs)
    end
  end

  describe "record_batch/1" do
    test "creates multiple events with correct sequence", %{trace: trace} do
      events = [
        %{
          trace_id: trace.id,
          module: "TestApp.Accounts",
          function: "get_user",
          arity: 1,
          event_type: :context_call
        },
        %{
          trace_id: trace.id,
          module: "TestApp.Catalog",
          function: "list_products",
          arity: 0,
          event_type: :context_call
        },
        %{
          trace_id: trace.id,
          module: "TestApp.Orders",
          function: "create_order",
          arity: 1,
          event_type: :context_call
        }
      ]

      assert {:ok, created_events} = TraceEvents.record_events(events)
      assert length(created_events) == 3
      assert Enum.at(created_events, 0).sequence_index == 0
      assert Enum.at(created_events, 1).sequence_index == 1
      assert Enum.at(created_events, 2).sequence_index == 2
    end
  end

  describe "list_trace_events/1" do
    test "returns events ordered by sequence_index", %{trace: trace} do
      {:ok, _event1} = TraceEvents.record_event(%{
        trace_id: trace.id,
        module: "TestApp",
        function: "fn1",
        arity: 0
      })

      {:ok, _event2} = TraceEvents.record_event(%{
        trace_id: trace.id,
        module: "TestApp",
        function: "fn2",
        arity: 0
      })

      {:ok, _event3} = TraceEvents.record_event(%{
        trace_id: trace.id,
        module: "TestApp",
        function: "fn3",
        arity: 0
      })

      events = TraceEvents.list_trace_events(trace.id)
      assert length(events) == 3
      assert Enum.at(events, 0).sequence_index == 0
      assert Enum.at(events, 1).sequence_index == 1
      assert Enum.at(events, 2).sequence_index == 2
    end

    test "returns empty list when no events" do
      {:ok, app} = Apps.create_app(%{
        name: "Empty App",
        slug: "empty-app",
        owner_id: UUID.uuid4()
      })

      {:ok, trace} = Traces.start_trace(%{
        app_id: app.id,
        entry_point: "GET /test"
      })

      assert TraceEvents.list_trace_events(trace.id) == []
    end
  end

  describe "get_context_flow/1" do
    test "groups events by context", %{app: app, trace: trace} do
      # Create contexts
      alias PhireFlight.Contexts
      {:ok, context1} = Contexts.create_app_context(%{
        app_id: app.id,
        name: "Accounts",
        full_name: "TestApp.Accounts",
        kind: :domain
      })

      {:ok, context2} = Contexts.create_app_context(%{
        app_id: app.id,
        name: "Catalog",
        full_name: "TestApp.Catalog",
        kind: :domain
      })

      # Record events with contexts
      {:ok, _event1} = TraceEvents.record_event(%{
        trace_id: trace.id,
        module: "TestApp.Accounts",
        function: "get_user",
        arity: 1,
        app_context_id: context1.id
      })

      {:ok, _event2} = TraceEvents.record_event(%{
        trace_id: trace.id,
        module: "TestApp.Accounts",
        function: "update_user",
        arity: 2,
        app_context_id: context1.id
      })

      {:ok, _event3} = TraceEvents.record_event(%{
        trace_id: trace.id,
        module: "TestApp.Catalog",
        function: "list_products",
        arity: 0,
        app_context_id: context2.id
      })

      flow = TraceEvents.get_context_flow(trace.id)
      assert length(flow) == 2

      {accounts_context, accounts_count} = Enum.find(flow, fn {ctx, _count} -> ctx.id == context1.id end)
      assert accounts_context.name == "Accounts"
      assert accounts_count == 2

      {catalog_context, catalog_count} = Enum.find(flow, fn {ctx, _count} -> ctx.id == context2.id end)
      assert catalog_context.name == "Catalog"
      assert catalog_count == 1
    end
  end
end

