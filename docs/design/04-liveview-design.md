# PhireFlight LiveView Design

## Overview
This document defines all LiveView modules, components, routes, and UI interactions.

---

## Router Configuration

**File:** `lib/phireflight_web/router.ex`

```elixir
defmodule PhireFlightWeb.Router do
  use PhireFlightWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {PhireFlightWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :fetch_current_user
  end

  pipeline :api do
    plug :accepts, ["json"]
    plug :authenticate_api_key
  end

  scope "/", PhireFlightWeb do
    pipe_through :browser

    get "/", PageController, :home

    live_session :require_authenticated_user,
      on_mount: [{PhireFlightWeb.UserAuth, :ensure_authenticated}] do
      # Apps
      live "/apps", AppsLive.Index, :index
      live "/apps/new", AppsLive.Index, :new
      live "/apps/:id/edit", AppsLive.Index, :edit
      live "/apps/:id", AppsLive.Show, :show
      live "/apps/:id/show/edit", AppsLive.Show, :edit

      # Contexts
      live "/apps/:app_id/contexts", ContextsLive.Index, :index
      live "/apps/:app_id/contexts/new", ContextsLive.Index, :new
      live "/apps/:app_id/contexts/:id/edit", ContextsLive.Index, :edit

      # Traces (the star of the show)
      live "/apps/:app_id/traces", TracesLive.Index, :index
      live "/apps/:app_id/traces/:id", TracesLive.Show, :show

      # Layouts
      live "/apps/:app_id/layouts", LayoutsLive.Index, :index
      live "/apps/:app_id/layouts/:id/edit", LayoutsLive.Index, :edit
    end
  end

  scope "/api", PhireFlightWeb.API do
    pipe_through :api

    post "/traces", TraceController, :create
    post "/traces/:trace_id/events", EventController, :create
    post "/traces/:trace_id/finish", TraceController, :finish
  end

  # Auth routes (registration, login, etc.)
  scope "/", PhireFlightWeb do
    pipe_through [:browser, :redirect_if_user_is_authenticated]

    live_session :redirect_if_user_is_authenticated,
      on_mount: [{PhireFlightWeb.UserAuth, :redirect_if_user_is_authenticated}] do
      live "/users/register", UserRegistrationLive, :new
      live "/users/log_in", UserLoginLive, :new
      live "/users/reset_password", UserForgotPasswordLive, :new
      live "/users/reset_password/:token", UserResetPasswordLive, :edit
    end

    post "/users/log_in", UserSessionController, :create
  end

  scope "/", PhireFlightWeb do
    pipe_through [:browser, :require_authenticated_user]

    live_session :require_authenticated_user,
      on_mount: [{PhireFlightWeb.UserAuth, :ensure_authenticated}] do
      live "/users/settings", UserSettingsLive, :edit
      live "/users/settings/confirm_email/:token", UserSettingsLive, :confirm_email
    end
  end

  scope "/", PhireFlightWeb do
    pipe_through [:browser]

    delete "/users/log_out", UserSessionController, :delete

    live_session :current_user,
      on_mount: [{PhireFlightWeb.UserAuth, :mount_current_user}] do
      live "/users/confirm/:token", UserConfirmationLive, :edit
      live "/users/confirm", UserConfirmationInstructionsLive, :new
    end
  end
end
```

---

## LiveView Modules

### AppsLive.Index

**File:** `lib/phireflight_web/live/apps_live/index.ex`

```elixir
defmodule PhireFlightWeb.AppsLive.Index do
  use PhireFlightWeb, :live_view

  alias PhireFlight.Apps
  alias PhireFlight.Apps.App

  @impl true
  def mount(_params, _session, socket) do
    {:ok, stream(socket, :apps, Apps.list_apps(socket.assigns.current_user.id))}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit App")
    |> assign(:app, Apps.get_app!(id))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New App")
    |> assign(:app, %App{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Apps")
    |> assign(:app, nil)
  end

  @impl true
  def handle_info({PhireFlightWeb.AppsLive.FormComponent, {:saved, app}}, socket) do
    {:noreply, stream_insert(socket, :apps, app)}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    app = Apps.get_app!(id)
    {:ok, _} = Apps.delete_app(app)

    {:noreply, stream_delete(socket, :apps, app)}
  end
end
```

**Template:** `lib/phireflight_web/live/apps_live/index.html.heex`

```heex
<.header>
  Apps
  <:actions>
    <.link patch={~p"/apps/new"}>
      <.button>New App</.button>
    </.link>
  </:actions>
</.header>

<.table
  id="apps"
  rows={@streams.apps}
  row_click={fn {_id, app} -> JS.navigate(~p"/apps/#{app}") end}
>
  <:col :let={{_id, app}} label="Name"><%= app.name %></:col>
  <:col :let={{_id, app}} label="Slug"><%= app.slug %></:col>
  <:col :let={{_id, app}} label="Contexts">
    <%= length(app.app_contexts || []) %>
  </:col>
  <:action :let={{_id, app}}>
    <.link navigate={~p"/apps/#{app}"}>View</.link>
  </:action>
  <:action :let={{id, app}}>
    <.link patch={~p"/apps/#{app}/edit"}>Edit</.link>
  </:action>
  <:action :let={{id, app}}>
    <.link
      phx-click={JS.push("delete", value: %{id: app.id}) |> hide("##{id}")}
      data-confirm="Are you sure?"
    >
      Delete
    </.link>
  </:action>
</.table>

<.modal :if={@live_action in [:new, :edit]} id="app-modal" show on_cancel={JS.patch(~p"/apps")}>
  <.live_component
    module={PhireFlightWeb.AppsLive.FormComponent}
    id={@app.id || :new}
    title={@page_title}
    action={@live_action}
    app={@app}
    current_user={@current_user}
    patch={~p"/apps"}
  />
</.modal>
```

---

### AppsLive.Show

**File:** `lib/phireflight_web/live/apps_live/show.ex`

```elixir
defmodule PhireFlightWeb.AppsLive.Show do
  use PhireFlightWeb, :live_view

  alias PhireFlight.{Apps, Contexts, Traces}

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"id" => id}, _, socket) do
    app = Apps.get_app!(id)
    contexts = Contexts.list_app_contexts(id)
    recent_traces = Traces.list_traces(id, limit: 20)
    stats = Traces.get_trace_stats(id)

    {:noreply,
     socket
     |> assign(:page_title, app.name)
     |> assign(:app, app)
     |> assign(:contexts, contexts)
     |> assign(:recent_traces, recent_traces)
     |> assign(:stats, stats)}
  end
end
```

**Template:** `lib/phireflight_web/live/apps_live/show.html.heex`

```heex
<.header>
  <%= @app.name %>
  <:subtitle><%= @app.description %></:subtitle>
  <:actions>
    <.link patch={~p"/apps/#{@app}/show/edit"} phx-click={JS.push_focus()}>
      <.button>Edit app</.button>
    </.link>
    <.link navigate={~p"/apps/#{@app}/contexts"}>
      <.button>Manage Contexts</.button>
    </.link>
  </:actions>
</.header>

<!-- Stats Cards -->
<div class="grid grid-cols-1 md:grid-cols-4 gap-4 my-8">
  <div class="bg-white dark:bg-gray-800 rounded-lg shadow p-6">
    <div class="text-sm text-gray-500 dark:text-gray-400">Total Traces</div>
    <div class="text-3xl font-bold"><%= @stats.total_count %></div>
  </div>
  <div class="bg-white dark:bg-gray-800 rounded-lg shadow p-6">
    <div class="text-sm text-gray-500 dark:text-gray-400">Success Rate</div>
    <div class="text-3xl font-bold text-green-600">
      <%= if @stats.total_count > 0 do %>
        <%= trunc(@stats.ok_count / @stats.total_count * 100) %>%
      <% else %>
        --
      <% end %>
    </div>
  </div>
  <div class="bg-white dark:bg-gray-800 rounded-lg shadow p-6">
    <div class="text-sm text-gray-500 dark:text-gray-400">Avg Duration</div>
    <div class="text-3xl font-bold"><%= @stats.avg_duration_ms || 0 %>ms</div>
  </div>
  <div class="bg-white dark:bg-gray-800 rounded-lg shadow p-6">
    <div class="text-sm text-gray-500 dark:text-gray-400">Contexts</div>
    <div class="text-3xl font-bold"><%= length(@contexts) %></div>
  </div>
</div>

<!-- Context Map -->
<.header class="mt-8">
  Context Map
  <:actions>
    <.link navigate={~p"/apps/#{@app}/contexts"}>
      <.button>Manage</.button>
    </.link>
  </:actions>
</.header>

<div class="grid grid-cols-1 md:grid-cols-3 lg:grid-cols-4 gap-4 my-6">
  <%= for context <- @contexts do %>
    <.context_card context={context} />
  <% end %>
</div>

<!-- Recent Traces -->
<.header class="mt-8">
  Recent Flights
  <:actions>
    <.link navigate={~p"/apps/#{@app}/traces"}>
      <.button>View All</.button>
    </.link>
  </:actions>
</.header>

<.table id="recent_traces" rows={@recent_traces}>
  <:col :let={trace} label="Entry Point"><%= trace.entry_point %></:col>
  <:col :let={trace} label="Status">
    <.status_badge status={trace.status} />
  </:col>
  <:col :let={trace} label="Duration"><%= trace.duration_ms %>ms</:col>
  <:col :let={trace} label="Started">
    <%= Calendar.strftime(trace.started_at, "%Y-%m-%d %H:%M:%S") %>
  </:col>
  <:action :let={trace}>
    <.link navigate={~p"/apps/#{@app}/traces/#{trace}"}>
      View Flight →
    </.link>
  </:action>
</.table>
```

---

### TracesLive.Show (Flight Replay) ⭐

**File:** `lib/phireflight_web/live/traces_live/show.ex`

```elixir
defmodule PhireFlightWeb.TracesLive.Show do
  use PhireFlightWeb, :live_view

  alias PhireFlight.{Traces, TraceEvents, Narrations, Apps}

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

    {:noreply,
     socket
     |> assign(:page_title, "Flight: #{trace.entry_point}")
     |> assign(:app, app)
     |> assign(:trace, trace)
     |> assign(:events, events)
     |> assign(:context_flow, context_flow)
     |> assign(:transitions, transitions)
     |> assign(:narration, narration)
     |> assign(:selected_event, nil)
     |> assign(:playing, false)
     |> assign(:current_event_index, 0)}
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
```

**Template:** `lib/phireflight_web/live/traces_live/show.html.heex`

```heex
<.header>
  Flight Replay
  <:subtitle>
    <%= @trace.entry_point %> •
    <.status_badge status={@trace.status} /> •
    <%= @trace.duration_ms %>ms
  </:subtitle>
  <:actions>
    <.button phx-click="play">
      <%= if @playing, do: "⏸ Pause", else: "▶ Play" %>
    </.button>
    <.button phx-click="reset">Reset</.button>
    <.link navigate={~p"/apps/#{@app}"}>
      <.button>← Back to App</.button>
    </.link>
  </:actions>
</.header>

<div class="grid grid-cols-1 lg:grid-cols-3 gap-6 mt-6">
  <!-- Left: Context Diagram (2/3 width on large screens) -->
  <div class="lg:col-span-2">
    <div class="bg-white dark:bg-gray-800 rounded-lg shadow p-6">
      <h3 class="text-lg font-semibold mb-4">Context Flow</h3>
      <.trace_diagram
        app={@app}
        trace={@trace}
        context_flow={@context_flow}
        transitions={@transitions}
        selected_event={@selected_event}
        current_event_index={@current_event_index}
      />
    </div>
  </div>

  <!-- Right: Timeline + Narration (1/3 width) -->
  <div class="space-y-6">
    <!-- Narration Panel -->
    <div class="bg-white dark:bg-gray-800 rounded-lg shadow p-6">
      <h3 class="text-lg font-semibold mb-4">AI Narration</h3>
      <%= if @narration do %>
        <.narration_panel narration={@narration} />
      <% else %>
        <p class="text-gray-500 dark:text-gray-400 mb-4">
          No narration yet.
        </p>
        <.button phx-click="generate_narration" disabled={@generating_narration}>
          <%= if @generating_narration, do: "Generating...", else: "Generate Narration" %>
        </.button>
      <% end %>
    </div>

    <!-- Timeline -->
    <div class="bg-white dark:bg-gray-800 rounded-lg shadow p-6">
      <h3 class="text-lg font-semibold mb-4">Timeline</h3>
      <.trace_timeline
        events={@events}
        selected_event={@selected_event}
        current_event_index={@current_event_index}
      />
    </div>
  </div>
</div>
```

---

## Components

### TraceDiagram Component

**File:** `lib/phireflight_web/components/trace_diagram.ex`

```elixir
defmodule PhireFlightWeb.Components.TraceDiagram do
  use Phoenix.Component

  attr :app, :map, required: true
  attr :trace, :map, required: true
  attr :context_flow, :list, required: true
  attr :transitions, :list, required: true
  attr :selected_event, :map, default: nil
  attr :current_event_index, :integer, default: 0

  def trace_diagram(assigns) do
    ~H"""
    <div
      id="trace-diagram"
      class="w-full h-96 border border-gray-300 dark:border-gray-600 rounded"
      phx-hook="TraceDiagram"
      data-context-flow={Jason.encode!(@context_flow)}
      data-transitions={Jason.encode!(@transitions)}
      data-current-index={@current_event_index}
    >
      <!-- SVG diagram rendered by JavaScript hook -->
    </div>
    """
  end
end
```

### TraceTimeline Component

**File:** `lib/phireflight_web/components/trace_timeline.ex`

```elixir
defmodule PhireFlightWeb.Components.TraceTimeline do
  use Phoenix.Component

  attr :events, :list, required: true
  attr :selected_event, :map, default: nil
  attr :current_event_index, :integer, default: 0

  def trace_timeline(assigns) do
    ~H"""
    <div class="space-y-2 max-h-96 overflow-y-auto">
      <%= for {event, index} <- Enum.with_index(@events) do %>
        <div
          class={[
            "p-3 rounded cursor-pointer transition-colors",
            index == @current_event_index && "bg-blue-100 dark:bg-blue-900",
            @selected_event && @selected_event.id == event.id && "ring-2 ring-blue-500",
            event.error && "border-l-4 border-red-500"
          ]}
          phx-click="select_event"
          phx-value-event_id={event.id}
        >
          <div class="flex items-start justify-between">
            <div class="flex-1">
              <div class="text-xs text-gray-500 dark:text-gray-400">
                T+<%= event.started_at && @events |> hd() |> then(& DateTime.diff(event.started_at, &1.started_at, :millisecond)) %>ms
              </div>
              <div class="font-mono text-sm">
                <%= event.module %>.<%= event.function %>/<%= event.arity %>
              </div>
              <div class="text-xs text-gray-600 dark:text-gray-400">
                <%= event.event_type %> • <%= event.duration_ms %>ms
              </div>
            </div>
            <%= if event.error do %>
              <.icon name="hero-exclamation-circle" class="w-5 h-5 text-red-500" />
            <% end %>
          </div>
        </div>
      <% end %>
    </div>
    """
  end
end
```

### NarrationPanel Component

**File:** `lib/phireflight_web/components/narration_panel.ex`

```elixir
defmodule PhireFlightWeb.Components.NarrationPanel do
  use Phoenix.Component

  attr :narration, :map, required: true

  def narration_panel(assigns) do
    ~H"""
    <div class="space-y-4">
      <div>
        <h4 class="text-sm font-semibold text-gray-700 dark:text-gray-300 mb-2">
          Summary
        </h4>
        <p class="text-sm text-gray-600 dark:text-gray-400">
          <%= @narration.summary %>
        </p>
      </div>

      <%= if @narration.details do %>
        <div>
          <h4 class="text-sm font-semibold text-gray-700 dark:text-gray-300 mb-2">
            Details
          </h4>
          <p class="text-sm text-gray-600 dark:text-gray-400">
            <%= @narration.details %>
          </p>
        </div>
      <% end %>

      <%= if @narration.issues && length(@narration.issues) > 0 do %>
        <div>
          <h4 class="text-sm font-semibold text-gray-700 dark:text-gray-300 mb-2">
            Issues Found
          </h4>
          <div class="space-y-2">
            <%= for issue <- @narration.issues do %>
              <div class={[
                "p-2 rounded text-sm",
                issue["severity"] == "error" && "bg-red-100 dark:bg-red-900 text-red-800 dark:text-red-200",
                issue["severity"] == "warn" && "bg-yellow-100 dark:bg-yellow-900 text-yellow-800 dark:text-yellow-200",
                issue["severity"] == "info" && "bg-blue-100 dark:bg-blue-900 text-blue-800 dark:text-blue-200"
              ]}>
                <div class="font-semibold"><%= issue["type"] %></div>
                <div><%= issue["description"] %></div>
              </div>
            <% end %>
          </div>
        </div>
      <% end %>

      <div class="text-xs text-gray-500 dark:text-gray-400">
        Generated by <%= @narration.model_name %> in <%= @narration.generation_time_ms %>ms
      </div>
    </div>
    """
  end
end
```

### ContextCard Component

**File:** `lib/phireflight_web/components/context_card.ex`

```elixir
defmodule PhireFlightWeb.Components.ContextCard do
  use Phoenix.Component

  attr :context, :map, required: true

  def context_card(assigns) do
    ~H"""
    <div
      class="p-4 rounded-lg border-2 hover:shadow-lg transition-shadow"
      style={@context.color && "border-color: #{@context.color}"}
    >
      <div class="flex items-start justify-between mb-2">
        <h3 class="font-semibold text-lg"><%= @context.name %></h3>
        <.kind_badge kind={@context.kind} />
      </div>
      <%= if @context.description do %>
        <p class="text-sm text-gray-600 dark:text-gray-400"><%= @context.description %></p>
      <% end %>
    </div>
    """
  end

  defp kind_badge(assigns) do
    ~H"""
    <span class={[
      "text-xs px-2 py-1 rounded",
      @kind == :domain && "bg-blue-100 text-blue-800",
      @kind == :integration && "bg-purple-100 text-purple-800",
      @kind == :ui && "bg-green-100 text-green-800",
      @kind == :infra && "bg-gray-100 text-gray-800"
    ]}>
      <%= @kind %>
    </span>
    """
  end
end
```

### StatusBadge Component

**File:** `lib/phireflight_web/components/status_badge.ex`

```elixir
defmodule PhireFlightWeb.Components.StatusBadge do
  use Phoenix.Component

  attr :status, :atom, required: true

  def status_badge(assigns) do
    ~H"""
    <span class={[
      "inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium",
      @status == :ok && "bg-green-100 text-green-800 dark:bg-green-800 dark:text-green-100",
      @status == :error && "bg-red-100 text-red-800 dark:bg-red-800 dark:text-red-100",
      @status == :timeout && "bg-yellow-100 text-yellow-800 dark:bg-yellow-800 dark:text-yellow-100",
      @status == :cancelled && "bg-gray-100 text-gray-800 dark:bg-gray-800 dark:text-gray-100"
    ]}>
      <%= @status %>
    </span>
    """
  end
end
```

---

## JavaScript Hooks

### TraceDiagram Hook

**File:** `assets/js/hooks/trace_diagram.js`

```javascript
export const TraceDiagram = {
  mounted() {
    this.renderDiagram();

    this.handleEvent("update_diagram", ({context_flow, transitions, current_index}) => {
      this.updateDiagram(context_flow, transitions, current_index);
    });
  },

  updated() {
    const currentIndex = parseInt(this.el.dataset.currentIndex);
    this.highlightEventAtIndex(currentIndex);
  },

  renderDiagram() {
    const contextFlow = JSON.parse(this.el.dataset.contextFlow);
    const transitions = JSON.parse(this.el.dataset.transitions);

    // Use D3.js or similar to render:
    // - Nodes for each context
    // - Edges for transitions
    // - Animation support

    // Example structure (pseudo-code):
    // const svg = d3.select(this.el).append("svg")...
    // const nodes = contextFlow.map((context, i) => ({
    //   id: context.id,
    //   label: context.name,
    //   x: i * 150,
    //   y: 100
    // }));
    // const links = transitions.map(t => ({
    //   source: t.from_context_id,
    //   target: t.to_context_id,
    //   count: t.count
    // }));
    // ... render with force-directed layout or manual positioning
  },

  updateDiagram(contextFlow, transitions, currentIndex) {
    // Update highlighting based on current playback position
  },

  highlightEventAtIndex(index) {
    // Highlight the current event's context and transition
  }
};
```

### TimelinePlayer Hook

**File:** `assets/js/hooks/timeline_player.js`

```javascript
export const TimelinePlayer = {
  mounted() {
    // Auto-scroll timeline to current event
    this.scrollToCurrentEvent();
  },

  updated() {
    this.scrollToCurrentEvent();
  },

  scrollToCurrentEvent() {
    const currentIndex = parseInt(this.el.dataset.currentIndex);
    const eventElements = this.el.querySelectorAll('[data-event-index]');
    const currentElement = eventElements[currentIndex];

    if (currentElement) {
      currentElement.scrollIntoView({ behavior: 'smooth', block: 'nearest' });
    }
  }
};
```

---

## Summary

**LiveView Architecture:**
- ✅ **Apps** - List and manage observed apps
- ✅ **Contexts** - Define logical contexts per app
- ✅ **Traces** - View trace index and individual flight replays
- ✅ **Flight Replay** - Interactive diagram + timeline + AI narration
- ✅ **Real-time updates** - Using Phoenix PubSub for live trace updates (future)
- ✅ **Component composition** - Reusable components for diagrams, timelines, narrations
- ✅ **JavaScript hooks** - For interactive diagram rendering

**Key UX Features:**
- 🎬 **Playback controls** - Play/pause/reset trace replay
- 🔍 **Event selection** - Click timeline events to highlight in diagram
- 🤖 **On-demand AI** - Generate narration button (async)
- 📊 **Stats dashboard** - Quick metrics per app
- 🎨 **Tailwind styling** - Modern, responsive UI
