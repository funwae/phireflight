defmodule PhireFlightWeb.TracesLive.Index do
  use PhireFlightWeb, :live_view

  alias PhireFlight.{Traces, Apps}
  import PhireFlightWeb.Components.StatusBadge

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"app_id" => app_id} = params, _url, socket) do
    app = Apps.get_app!(app_id)
    status_filter = params["status"]

    traces =
      if status_filter && status_filter != "" do
        status_atom = String.to_existing_atom(status_filter)
        Traces.list_traces(app_id, limit: 100, status: status_atom)
      else
        Traces.list_traces(app_id, limit: 100)
      end

    {:noreply,
     socket
     |> assign(:page_title, "Flights - #{app.name}")
     |> assign(:app, app)
     |> assign(:traces, traces)
     |> assign(:status_filter, status_filter || "")}
  end

  @impl true
  def handle_event("filter", %{"status" => status}, socket) do
    {:noreply, push_patch(socket, to: ~p"/apps/#{socket.assigns.app.id}/traces?status=#{status}")}
  end
end

