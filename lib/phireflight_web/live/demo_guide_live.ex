defmodule PhireFlightWeb.DemoGuideLive do
  @moduledoc """
  Guided demo tour LiveView for PhireFlight.
  """
  use PhireFlightWeb, :live_view

  alias PhireFlight.{Apps, Traces}


  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:step, 1)
     |> assign(:latest_flight, nil)
     |> assign(:polling, false)}
  end

  @impl true
  def handle_params(_params, _url, socket) do
    {:noreply, assign(socket, :page_title, "Demo Guide")}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="max-w-4xl mx-auto">
      <%= cond do %>
        <% @step == 1 -> %>
          <%= render_step1(assigns) %>
        <% @step == 2 -> %>
          <%= render_step2(assigns) %>
        <% @step == 3 -> %>
          <%= render_step3(assigns) %>
      <% end %>
    </div>
    """
  end

  defp render_step1(assigns) do
    ~H"""
    <div class="bg-slate-900 border border-slate-800 rounded-xl p-8">
      <h1 class="text-3xl font-semibold text-slate-100 tracking-tight mb-4">Welcome to PhireFlight</h1>
      <p class="text-slate-300 text-lg leading-relaxed mb-6">
        PhireFlight is a flight recorder for Phoenix contexts. Every request becomes a visual 'flight' you can replay as a diagram and a story.
      </p>
      <p class="text-slate-400 text-sm leading-relaxed mb-8">
        You know how Phoenix contexts are supposed to be the architectural backbone — but once AI and junior devs start pushing code, it's hard to see if the app still follows your context boundaries? PhireFlight records those contexts at runtime and lets an AI narrate what's actually happening.
      </p>
      <div class="flex gap-4">
        <.button phx-click="next_step" phx-value-step="2" class="bg-orange-500 hover:bg-orange-600 text-white">
          Run Happy Path Demo
        </.button>
        <.button phx-click="skip_to_flights" class="bg-slate-800 hover:bg-slate-700 text-slate-200 border border-slate-700">
          Skip to Flights
        </.button>
      </div>
    </div>
    """
  end

  defp render_step2(assigns) do
    ~H"""
    <div class="bg-slate-900 border border-slate-800 rounded-xl p-8">
      <h2 class="text-2xl font-semibold text-slate-100 tracking-tight mb-6">Step 2: Trigger a Flight</h2>

      <div class="grid grid-cols-1 lg:grid-cols-2 gap-6">
        <!-- Left: DemoShop Link -->
        <div class="bg-slate-800 border border-slate-700 rounded-lg p-6">
          <h3 class="text-lg font-semibold text-slate-100 mb-3">DemoShop</h3>
          <p class="text-slate-400 text-sm mb-4">
            In the other tab/window, perform a checkout. When you're done, come back here and click "I've completed a checkout".
          </p>
          <div class="space-y-2 mb-4">
            <div class="flex items-center gap-2 text-sm text-slate-300">
              <span class="w-5 h-5 rounded-full bg-orange-500/20 border border-orange-500/30 flex items-center justify-center text-xs">1</span>
              <span>Browse products</span>
            </div>
            <div class="flex items-center gap-2 text-sm text-slate-300">
              <span class="w-5 h-5 rounded-full bg-orange-500/20 border border-orange-500/30 flex items-center justify-center text-xs">2</span>
              <span>Add items to cart</span>
            </div>
            <div class="flex items-center gap-2 text-sm text-slate-300">
              <span class="w-5 h-5 rounded-full bg-orange-500/20 border border-orange-500/30 flex items-center justify-center text-xs">3</span>
              <span>Complete checkout</span>
            </div>
          </div>
          <.link navigate={~p"/demo/products"} target="_blank" class="inline-flex items-center rounded-md bg-orange-500 px-4 py-2 text-sm font-semibold text-white hover:bg-orange-600">
            Open DemoShop →
          </.link>
        </div>

        <!-- Right: Checklist -->
        <div class="bg-slate-800 border border-slate-700 rounded-lg p-6">
          <h3 class="text-lg font-semibold text-slate-100 mb-4">Checklist</h3>
          <div class="space-y-3">
            <label class="flex items-center gap-3 cursor-pointer">
              <input type="checkbox" class="rounded border-slate-600 text-orange-500 focus:ring-orange-500" />
              <span class="text-slate-300">Added item to cart</span>
            </label>
            <label class="flex items-center gap-3 cursor-pointer">
              <input type="checkbox" class="rounded border-slate-600 text-orange-500 focus:ring-orange-500" />
              <span class="text-slate-300">Completed checkout</span>
            </label>
          </div>
          <div class="mt-6">
            <.button
              phx-click="check_for_flight"
              disabled={@polling}
              class="w-full bg-orange-500 hover:bg-orange-600 text-white disabled:opacity-50"
            >
              <%= if @polling, do: "Checking for flight...", else: "I've completed a checkout" %>
            </.button>
          </div>
        </div>
      </div>
    </div>
    """
  end

  defp render_step3(assigns) do
    ~H"""
    <div class="bg-slate-900 border border-slate-800 rounded-xl p-8">
      <h2 class="text-2xl font-semibold text-slate-100 tracking-tight mb-6">Step 3: Explore the Flight</h2>

      <%= if @latest_flight do %>
        <div class="mb-6 p-4 bg-slate-800 border border-slate-700 rounded-lg">
          <p class="text-slate-300 mb-4">
            Great! A flight was recorded. Click the link below to explore it:
          </p>
          <.link
            navigate={~p"/apps/#{@latest_flight.app_id}/traces/#{@latest_flight.id}"}
            class="inline-flex items-center rounded-md bg-orange-500 px-4 py-2 text-sm font-semibold text-white hover:bg-orange-600"
          >
            View Flight →
          </.link>
        </div>

        <div class="bg-slate-800 border border-slate-700 rounded-lg p-6">
          <h3 class="text-lg font-semibold text-slate-100 mb-4">What to Look For</h3>
          <div class="space-y-4 text-sm text-slate-300">
            <div class="flex items-start gap-3">
              <span class="text-orange-400 font-bold">1.</span>
              <div>
                <p class="font-semibold mb-1">Context Diagram</p>
                <p class="text-slate-400">This diagram shows which contexts participated in the flight. Each context is a node with a colored border.</p>
              </div>
            </div>
            <div class="flex items-start gap-3">
              <span class="text-orange-400 font-bold">2.</span>
              <div>
                <p class="font-semibold mb-1">Flight Timeline</p>
                <p class="text-slate-400">This timeline shows the sequence of calls. Each row is a concrete function call in a specific context, with timing.</p>
              </div>
            </div>
            <div class="flex items-start gap-3">
              <span class="text-orange-400 font-bold">3.</span>
              <div>
                <p class="font-semibold mb-1">AI Narration</p>
                <p class="text-slate-400">Click "Generate narration" to have the AI explain the flight in human terms, using the context descriptions.</p>
              </div>
            </div>
          </div>
        </div>
      <% else %>
        <div class="text-center py-8">
          <p class="text-slate-400 mb-4">No flight found yet.</p>
          <.button phx-click="check_for_flight" class="bg-orange-500 hover:bg-orange-600 text-white">
            Check Again
          </.button>
        </div>
      <% end %>
    </div>
    """
  end

  @impl true
  def handle_event("next_step", %{"step" => step}, socket) do
    step_num = String.to_integer(step)
    {:noreply, assign(socket, :step, step_num)}
  end

  @impl true
  def handle_event("skip_to_flights", _params, socket) do
    # Find DemoShop app
    case Apps.get_app_by_slug("demo-shop") do
      nil ->
        {:noreply,
         socket
         |> put_flash(:error, "DemoShop app not found. Please run seeds first.")
         |> assign(:step, 1)}

      app ->
        {:noreply, redirect(socket, to: ~p"/apps/#{app.id}/traces")}
    end
  end

  @impl true
  def handle_event("check_for_flight", _params, socket) do
    case Apps.get_app_by_slug("demo-shop") do
      nil ->
        {:noreply,
         socket
         |> put_flash(:error, "DemoShop app not found")
         |> assign(:polling, false)}

      app ->
        # Get most recent trace
        traces = Traces.list_traces(app.id, limit: 1)

        if length(traces) > 0 do
          latest = List.first(traces)
          {:noreply,
           socket
           |> assign(:latest_flight, latest)
           |> assign(:polling, false)
           |> assign(:step, 3)}
        else
          # Keep polling
          Process.send_after(self(), :poll_flight, 2000)
          {:noreply, assign(socket, :polling, true)}
        end
    end
  end

  @impl true
  def handle_info(:poll_flight, socket) do
    case Apps.get_app_by_slug("demo-shop") do
      nil ->
        {:noreply, assign(socket, :polling, false)}

      app ->
        traces = Traces.list_traces(app.id, limit: 1)

        if length(traces) > 0 do
          latest = List.first(traces)
          {:noreply,
           socket
           |> assign(:latest_flight, latest)
           |> assign(:polling, false)
           |> assign(:step, 3)}
        else
          Process.send_after(self(), :poll_flight, 2000)
          {:noreply, socket}
        end
    end
  end

  @impl true
  def handle_info(_msg, socket) do
    {:noreply, socket}
  end
end

