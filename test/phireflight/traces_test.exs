defmodule PhireFlight.TracesTest do
  use PhireFlight.DataCase

  alias PhireFlight.{Traces, Apps, Accounts}

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

    %{app: app, user: user}
  end

  describe "start_trace/1" do
    test "creates trace with required fields", %{app: app} do
      attrs = %{
        app_id: app.id,
        entry_point: "GET /test",
        external_id: UUID.uuid4()
      }

      assert {:ok, trace} = Traces.start_trace(attrs)
      assert trace.app_id == app.id
      assert trace.entry_point == "GET /test"
      assert trace.external_id == attrs.external_id
      assert trace.status == :pending
      assert trace.started_at != nil
      assert trace.finished_at == nil
      assert trace.duration_ms == nil
    end

    test "generates external_id if not provided", %{app: app} do
      attrs = %{
        app_id: app.id,
        entry_point: "GET /test"
      }

      assert {:ok, trace} = Traces.start_trace(attrs)
      assert trace.external_id != nil
    end

    test "returns error with invalid app_id" do
      attrs = %{
        app_id: UUID.uuid4(),
        entry_point: "GET /test"
      }

      assert {:error, %Ecto.Changeset{}} = Traces.start_trace(attrs)
    end
  end

  describe "finish_trace/2" do
    test "updates trace with status and duration", %{app: app} do
      {:ok, trace} = Traces.start_trace(%{
        app_id: app.id,
        entry_point: "GET /test"
      })

      # Simulate some time passing
      Process.sleep(10)

      assert {:ok, updated_trace} = Traces.finish_trace(trace, :ok)
      assert updated_trace.status == :ok
      assert updated_trace.finished_at != nil
      assert updated_trace.duration_ms != nil
      assert updated_trace.duration_ms >= 0
    end

    test "includes error info when provided", %{app: app} do
      {:ok, trace} = Traces.start_trace(%{
        app_id: app.id,
        entry_point: "GET /test"
      })

      error_info = %{
        class: "ArgumentError",
        message: "Invalid argument"
      }

      assert {:ok, updated_trace} = Traces.finish_trace(trace, :error, error_info)
      assert updated_trace.status == :error
      assert updated_trace.error_class == "ArgumentError"
      assert updated_trace.error_message == "Invalid argument"
    end

    test "returns error when trace not found" do
      fake_trace = %PhireFlight.Traces.Trace{id: UUID.uuid4()}
      assert {:error, :not_found} = Traces.finish_trace(fake_trace, :ok)
    end
  end

  describe "get_trace!/1" do
    test "returns trace when found", %{app: app} do
      {:ok, trace} = Traces.start_trace(%{
        app_id: app.id,
        entry_point: "GET /test"
      })

      assert Traces.get_trace!(trace.id) == trace
    end

    test "raises when trace not found" do
      assert_raise Ecto.NoResultsError, fn ->
        Traces.get_trace!(UUID.uuid4())
      end
    end
  end

  describe "list_traces/2" do
    test "returns traces for app", %{app: app} do
      {:ok, trace1} = Traces.start_trace(%{
        app_id: app.id,
        entry_point: "GET /test1"
      })

      {:ok, trace2} = Traces.start_trace(%{
        app_id: app.id,
        entry_point: "GET /test2"
      })

      traces = Traces.list_traces(app.id)
      assert length(traces) == 2
      assert Enum.any?(traces, &(&1.id == trace1.id))
      assert Enum.any?(traces, &(&1.id == trace2.id))
    end

    test "respects limit parameter", %{app: app} do
      {:ok, _trace1} = Traces.start_trace(%{
        app_id: app.id,
        entry_point: "GET /test1"
      })

      {:ok, _trace2} = Traces.start_trace(%{
        app_id: app.id,
        entry_point: "GET /test2"
      })

      traces = Traces.list_traces(app.id, limit: 1)
      assert length(traces) == 1
    end

    test "returns empty list when no traces" do
      {:ok, app} = Apps.create_app(%{
        name: "Empty App",
        slug: "empty-app",
        owner_id: UUID.uuid4()
      })

      assert Traces.list_traces(app.id) == []
    end
  end

  describe "get_trace_stats/1" do
    test "calculates stats correctly", %{app: app} do
      # Create successful trace
      {:ok, trace1} = Traces.start_trace(%{
        app_id: app.id,
        entry_point: "GET /test1"
      })
      {:ok, _} = Traces.finish_trace(trace1, :ok)

      # Create error trace
      {:ok, trace2} = Traces.start_trace(%{
        app_id: app.id,
        entry_point: "GET /test2"
      })
      {:ok, _} = Traces.finish_trace(trace2, :error)

      stats = Traces.get_trace_stats(app.id)
      assert stats.total_count == 2
      assert stats.ok_count == 1
      assert stats.error_count == 1
      assert stats.avg_duration_ms != nil
    end

    test "returns zero stats when no traces", %{app: app} do
      stats = Traces.get_trace_stats(app.id)
      assert stats.total_count == 0
      assert stats.ok_count == 0
      assert stats.error_count == 0
      assert stats.avg_duration_ms == nil
    end
  end
end

