defmodule PhireFlightWeb.AppsLive.Show do
  use PhireFlightWeb, :live_view

  alias PhireFlight.{Apps, Contexts, Traces}
  alias PhireFlight.Repo

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"id" => id}, _, socket) do
    app = Apps.get_app!(id) |> Repo.preload(:owner)
    contexts = Contexts.list_app_contexts(id)
    recent_traces = Traces.list_traces(id, limit: 10)
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

