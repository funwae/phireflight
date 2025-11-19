defmodule PhireFlight.NarrationsTest do
  use PhireFlight.DataCase

  alias PhireFlight.{Narrations, Traces, Apps, Accounts, TraceEvents, Contexts}

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

    {:ok, context} = Contexts.create_app_context(%{
      app_id: app.id,
      name: "Accounts",
      full_name: "TestApp.Accounts",
      kind: :domain
    })

    {:ok, trace} = Traces.start_trace(%{
      app_id: app.id,
      entry_point: "GET /test"
    })

    {:ok, _event} = TraceEvents.record_event(%{
      trace_id: trace.id,
      module: "TestApp.Accounts",
      function: "get_user",
      arity: 1,
      app_context_id: context.id,
      event_type: :context_call
    })

    {:ok, _} = Traces.finish_trace(trace, :ok)

    %{trace: trace, app: app}
  end

  describe "get_narration_by_trace_id/1" do
    test "returns narration when found", %{trace: trace} do
      {:ok, narration} = Narrations.create_narration(%{
        trace_id: trace.id,
        model_name: "test-model",
        summary: "Test summary",
        details: "Test details"
      })

      assert Narrations.get_narration_by_trace_id(trace.id) == narration
    end

    test "returns nil when not found" do
      assert Narrations.get_narration_by_trace_id(UUID.uuid4()) == nil
    end
  end

  describe "create_narration/1" do
    test "creates narration with valid attributes", %{trace: trace} do
      attrs = %{
        trace_id: trace.id,
        model_name: "test-model",
        summary: "Test summary",
        details: "Test details",
        issues: []
      }

      assert {:ok, %Narrations.Narration{} = narration} = Narrations.create_narration(attrs)
      assert narration.trace_id == trace.id
      assert narration.model_name == "test-model"
      assert narration.summary == "Test summary"
      assert narration.details == "Test details"
    end

    test "returns error with invalid attributes" do
      attrs = %{
        trace_id: UUID.uuid4(),  # Invalid trace_id
        model_name: ""
      }

      assert {:error, %Ecto.Changeset{}} = Narrations.create_narration(attrs)
    end
  end

  describe "generate_for_trace/2" do
    test "creates placeholder narration when none exists", %{trace: trace} do
      assert {:ok, %Narrations.Narration{} = narration} = Narrations.generate_for_trace(trace.id)
      assert narration.trace_id == trace.id
      assert narration.summary != nil
      assert narration.model_name == "placeholder"
    end

    test "returns existing narration when present", %{trace: trace} do
      {:ok, existing} = Narrations.create_narration(%{
        trace_id: trace.id,
        model_name: "existing-model",
        summary: "Existing summary"
      })

      assert {:ok, narration} = Narrations.generate_for_trace(trace.id)
      assert narration.id == existing.id
    end

    test "regenerates narration when regenerate option is true", %{trace: trace} do
      {:ok, existing} = Narrations.create_narration(%{
        trace_id: trace.id,
        model_name: "old-model",
        summary: "Old summary"
      })

      assert {:ok, narration} = Narrations.generate_for_trace(trace.id, regenerate: true)
      assert narration.id != existing.id
      assert narration.model_name == "placeholder"
    end
  end

  describe "update_narration/2" do
    test "updates narration with valid attributes", %{trace: trace} do
      {:ok, narration} = Narrations.create_narration(%{
        trace_id: trace.id,
        model_name: "test-model",
        summary: "Original summary"
      })

      attrs = %{summary: "Updated summary"}
      assert {:ok, updated} = Narrations.update_narration(narration, attrs)
      assert updated.summary == "Updated summary"
    end
  end

  describe "delete_narration/1" do
    test "deletes narration", %{trace: trace} do
      {:ok, narration} = Narrations.create_narration(%{
        trace_id: trace.id,
        model_name: "test-model",
        summary: "Test summary"
      })

      assert {:ok, _} = Narrations.delete_narration(narration)
      assert Narrations.get_narration_by_trace_id(trace.id) == nil
    end
  end
end

