defmodule PhireFlightWeb.AppsLive.Index do
  use PhireFlightWeb, :live_view

  alias PhireFlight.Apps
  alias PhireFlight.Apps.App

  @impl true
  def mount(_params, _session, socket) do
    # For now, we'll list all apps. Later we'll filter by current_user
    {:ok, stream(socket, :apps, Apps.list_all_apps())}
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

  @impl true
  def handle_event("close_modal", _params, socket) do
    {:noreply, push_patch(socket, to: ~p"/apps")}
  end
end

