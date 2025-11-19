defmodule PhireFlight.Instrumentation.ClientTest do
  use PhireFlight.DataCase

  alias PhireFlight.Instrumentation.Client
  alias PhireFlight.{Apps, Traces, TraceEvents, Accounts}

  setup do
    # Create a test user
    {:ok, user} = Accounts.register_user(%{
      email: "test@example.com",
      password: "password123456",
      name: "Test User"
    })

    # Create test app
    {:ok, app} = Apps.create_app(%{
      name: "Test App",
      slug: "test-app",
      owner_id: user.id
    })

    %{app: app, user: user}
  end

  describe "start_trace/1" do
    test "starts a new trace and stores trace_id in process dictionary", %{app: app} do
      {:ok, trace_id} = Client.start_trace(%{
        app_slug: app.slug,
        entry_point: "GET /test"
      })

      assert trace_id == Client.current_trace_id()
      assert Traces.get_trace!(trace_id)
    end

    test "returns error for unknown app" do
      assert {:error, :app_not_found} = Client.start_trace(%{
        app_slug: "nonexistent",
        entry_point: "GET /test"
      })
    end

    test "generates external_id if not provided", %{app: app} do
      {:ok, trace_id} = Client.start_trace(%{
        app_slug: app.slug,
        entry_point: "GET /test"
      })

      trace = Traces.get_trace!(trace_id)
      assert trace.external_id != nil
    end

    test "uses provided external_id", %{app: app} do
      external_id = UUID.uuid4()

      {:ok, trace_id} = Client.start_trace(%{
        app_slug: app.slug,
        entry_point: "GET /test",
        external_id: external_id
      })

      trace = Traces.get_trace!(trace_id)
      assert trace.external_id == external_id
    end
  end

  describe "record_step/1" do
    setup %{app: app} do
      {:ok, trace_id} = Client.start_trace(%{
        app_slug: app.slug,
        entry_point: "GET /test"
      })

      %{trace_id: trace_id}
    end

    test "records an event in the current trace", %{trace_id: trace_id} do
      :ok = Client.record_step(%{
        module: "TestApp.Accounts",
        function: "get_user",
        arity: 1,
        event_type: :context_call
      })

      events = TraceEvents.list_trace_events(trace_id)
      assert length(events) == 1
      assert hd(events).module == "TestApp.Accounts"
      assert hd(events).function == "get_user"
      assert hd(events).event_type == :context_call
    end

    test "auto-increments sequence_index", %{trace_id: trace_id} do
      Client.record_step(%{module: "Test", function: "fn1", arity: 0})
      Client.record_step(%{module: "Test", function: "fn2", arity: 0})
      Client.record_step(%{module: "Test", function: "fn3", arity: 0})

      events = TraceEvents.list_trace_events(trace_id)
      assert length(events) == 3
      assert Enum.at(events, 0).sequence_index == 0
      assert Enum.at(events, 1).sequence_index == 1
      assert Enum.at(events, 2).sequence_index == 2
    end

    test "creates context when context_name provided", %{app: app, trace_id: trace_id} do
      :ok = Client.record_step(%{
        module: "TestApp.Accounts",
        function: "get_user",
        arity: 1,
        event_type: :context_call,
        context_name: "Accounts"
      })

      events = TraceEvents.list_trace_events(trace_id)
      event = hd(events)
      assert event.app_context_id != nil

      # Verify context was created
      alias PhireFlight.Contexts
      context = Contexts.get_app_context!(event.app_context_id)
      assert context.name == "Accounts"
      assert context.app_id == app.id
    end

    test "returns error when no active trace" do
      assert {:error, :no_active_trace} = Client.record_step(%{
        module: "Test", function: "fn", arity: 0
      })
    end
  end

  describe "finish_trace/2" do
    setup %{app: app} do
      {:ok, trace_id} = Client.start_trace(%{
        app_slug: app.slug,
        entry_point: "GET /test"
      })

      %{trace_id: trace_id}
    end

    test "finishes trace with status", %{trace_id: trace_id} do
      :ok = Client.finish_trace(:ok)

      trace = Traces.get_trace!(trace_id)
      assert trace.status == :ok
      assert trace.finished_at != nil
      assert trace.duration_ms != nil
    end

    test "includes error info when provided", %{trace_id: trace_id} do
      :ok = Client.finish_trace(:error, %{
        class: "ArgumentError",
        message: "Invalid argument"
      })

      trace = Traces.get_trace!(trace_id)
      assert trace.status == :error
      assert trace.error_class == "ArgumentError"
      assert trace.error_message == "Invalid argument"
    end

    test "cleans up process dictionary", %{trace_id: trace_id} do
      assert Client.current_trace_id() == trace_id
      :ok = Client.finish_trace(:ok)
      assert Client.current_trace_id() == nil
    end

    test "returns error when no active trace" do
      assert {:error, :no_active_trace} = Client.finish_trace(:ok)
    end
  end

  describe "trace_function/4" do
    setup %{app: app} do
      {:ok, _trace_id} = Client.start_trace(%{
        app_slug: app.slug,
        entry_point: "GET /test"
      })

      :ok
    end

    test "traces a successful function call" do
      result = Client.trace_function("TestApp", "test_fn", 0, fn ->
        :ok
      end)

      assert result == :ok
      events = TraceEvents.list_trace_events(Client.current_trace_id())
      assert length(events) == 1

      event = hd(events)
      assert event.module == "TestApp"
      assert event.function == "test_fn"
      assert event.arity == 0
      assert event.duration_ms != nil
      assert event.error == false
    end

    test "traces a function that raises" do
      assert_raise RuntimeError, fn ->
        Client.trace_function("TestApp", "test_fn", 0, fn ->
          raise "test error"
        end)
      end

      events = TraceEvents.list_trace_events(Client.current_trace_id())
      assert length(events) == 1
      event = hd(events)
      assert event.error == true
      assert event.error_message == "test error"
    end

    test "detects event type from module name" do
      Client.trace_function("TestApp.Controller", "index", 2, fn -> :ok end)
      Client.trace_function("TestApp.Live", "mount", 3, fn -> :ok end)
      Client.trace_function("TestApp.Repo", "get", 2, fn -> :ok end)
      Client.trace_function("TestApp.Accounts", "get_user", 1, fn -> :ok end)

      events = TraceEvents.list_trace_events(Client.current_trace_id())
      assert Enum.at(events, 0).event_type == :controller
      assert Enum.at(events, 1).event_type == :liveview
      assert Enum.at(events, 2).event_type == :db_query
      assert Enum.at(events, 3).event_type == :context_call
    end

    test "extracts context name from module" do
      Client.trace_function("DemoShop.Accounts.User", "create", 1, fn -> :ok end)

      events = TraceEvents.list_trace_events(Client.current_trace_id())
      event = hd(events)
      # Context should be auto-created
      assert event.app_context_id != nil
    end
  end

  describe "current_trace_id/0" do
    test "returns nil when no trace active" do
      assert Client.current_trace_id() == nil
    end

    test "returns trace_id when trace active", %{app: app} do
      {:ok, trace_id} = Client.start_trace(%{
        app_slug: app.slug,
        entry_point: "GET /test"
      })

      assert Client.current_trace_id() == trace_id
    end
  end
end

