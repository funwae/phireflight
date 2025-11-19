defmodule PhireFlightWeb.TracesLive.Show do
  use PhireFlightWeb, :live_view

  alias PhireFlight.{Traces, TraceEvents, Narrations, Apps}
  import PhireFlightWeb.Components.StatusBadge

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"app_id" => app_id, "id" => trace_id}, _, socket) do
    app = Apps.get_app!(app_id)
    trace = Traces.get_trace_with_events!(trace_id)
    events = TraceEvents.list_trace_events(trace_id)
    context_flow = TraceEvents.get_context_flow(trace_id)
    transitions = TraceEvents.get_context_transitions(trace_id)
    narration = Narrations.get_narration_by_trace_id(trace_id)

    # Calculate time offsets for each event
    time_offsets = calculate_time_offsets(events)

    {:noreply,
     socket
     |> assign(:page_title, "Flight: #{trace.entry_point}")
     |> assign(:app, app)
     |> assign(:trace, trace)
     |> assign(:events, events)
     |> assign(:time_offsets, time_offsets)
     |> assign(:context_flow, context_flow)
     |> assign(:transitions, transitions)
     |> assign(:narration, narration)
     |> assign(:selected_event, nil)
     |> assign(:playing, false)
     |> assign(:current_event_index, 0)
     |> assign(:generating_narration, false)}
  end

  defp calculate_time_offsets(events) do
    events
    |> Enum.with_index()
    |> Enum.map(fn {_event, index} ->
      events
      |> Enum.take(index + 1)
      |> Enum.reduce(0, fn event, acc -> acc + (event.duration_ms || 0) end)
    end)
  end

  @impl true
  def handle_event("select_event", %{"event_id" => event_id}, socket) do
    event = Enum.find(socket.assigns.events, &(&1.id == event_id))
    {:noreply, assign(socket, :selected_event, event)}
  end

  @impl true
  def handle_event("generate_narration", _params, socket) do
    trace_id = socket.assigns.trace.id

    Task.async(fn ->
      Narrations.generate_for_trace(trace_id)
    end)

    {:noreply,
     socket
     |> put_flash(:info, "Generating narration...")
     |> assign(:generating_narration, true)}
  end

  @impl true
  def handle_event("play", _params, socket) do
    if socket.assigns.playing do
      {:noreply, assign(socket, :playing, false)}
    else
      send(self(), :tick)
      {:noreply, assign(socket, :playing, true)}
    end
  end

  @impl true
  def handle_event("reset", _params, socket) do
    {:noreply,
     socket
     |> assign(:playing, false)
     |> assign(:current_event_index, 0)
     |> assign(:selected_event, nil)}
  end

  @impl true
  def handle_info(:tick, socket) do
    if socket.assigns.playing do
      next_index = socket.assigns.current_event_index + 1

      if next_index < length(socket.assigns.events) do
        Process.send_after(self(), :tick, 500)

        {:noreply,
         socket
         |> assign(:current_event_index, next_index)
         |> assign(:selected_event, Enum.at(socket.assigns.events, next_index))}
      else
        {:noreply, assign(socket, :playing, false)}
      end
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_info({_ref, {:ok, narration}}, socket) do
    {:noreply,
     socket
     |> assign(:narration, narration)
     |> assign(:generating_narration, false)
     |> put_flash(:info, "Narration generated!")}
  end

  @impl true
  def handle_info({:DOWN, _ref, :process, _pid, _reason}, socket) do
    {:noreply, socket}
  end
end

