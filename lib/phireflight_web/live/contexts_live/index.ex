defmodule PhireFlightWeb.ContextsLive.Index do
  use PhireFlightWeb, :live_view

  alias PhireFlight.{Contexts, Apps}
  alias PhireFlight.Contexts.AppContext

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"app_id" => app_id} = params, _url, socket) do
    app = Apps.get_app!(app_id)
    {:noreply, apply_action(socket, socket.assigns.live_action, params, app)}
  end

  defp apply_action(socket, :edit, %{"app_id" => app_id, "id" => id}, app) do
    socket
    |> assign(:page_title, "Edit Context")
    |> assign(:app, app)
    |> assign(:app_context, Contexts.get_app_context!(id))
  end

  defp apply_action(socket, :new, %{"app_id" => app_id}, app) do
    socket
    |> assign(:page_title, "New Context")
    |> assign(:app, app)
    |> assign(:app_context, %AppContext{app_id: app_id})
  end

  defp apply_action(socket, :index, %{"app_id" => app_id}, app) do
    contexts = Contexts.list_app_contexts(app_id)

    socket
    |> assign(:page_title, "Contexts - #{app.name}")
    |> assign(:app, app)
    |> assign(:app_context, nil)
    |> stream(:contexts, contexts)
  end

  @impl true
  def handle_info({PhireFlightWeb.ContextsLive.FormComponent, {:saved, app_context}}, socket) do
    {:noreply, stream_insert(socket, :contexts, app_context)}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    app_context = Contexts.get_app_context!(id)
    {:ok, _} = Contexts.delete_app_context(app_context)

    {:noreply, stream_delete(socket, :contexts, app_context)}
  end
end

