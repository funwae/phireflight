defmodule PhireFlightWeb.AppsLive.FormComponent do
  use PhireFlightWeb, :live_component

  alias PhireFlight.Apps

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        <%= @title %>
        <:subtitle>Use this form to manage app records in your database.</:subtitle>
      </.header>

      <.simple_form
        for={@form}
        id="app-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.input field={@form[:name]} type="text" label="Name" />
        <.input field={@form[:slug]} type="text" label="Slug" />
        <.input field={@form[:description]} type="textarea" label="Description" />
        <.input field={@form[:active]} type="checkbox" label="Active" />
        <:actions>
          <.button phx-disable-with="Saving...">Save App</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(%{app: app} = assigns, socket) do
    changeset = Apps.change_app(app)

    {:ok,
     socket
     |> assign(assigns)
     |> assign_form(changeset)}
  end

  @impl true
  def handle_event("validate", %{"app" => app_params}, socket) do
    changeset =
      socket.assigns.app
      |> Apps.change_app(app_params)
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset)}
  end

  def handle_event("save", %{"app" => app_params}, socket) do
    save_app(socket, socket.assigns.action, app_params)
  end

  defp save_app(socket, :edit, app_params) do
    case Apps.update_app(socket.assigns.app, app_params) do
      {:ok, app} ->
        notify_parent({:saved, app})

        {:noreply,
         socket
         |> put_flash(:info, "App updated successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp save_app(socket, :new, app_params) do
    # For now, we'll use a placeholder owner_id. Later this will come from current_user
    app_params = Map.put(app_params, "owner_id", Ecto.UUID.generate())

    case Apps.create_app(app_params) do
      {:ok, app} ->
        notify_parent({:saved, app})

        {:noreply,
         socket
         |> put_flash(:info, "App created successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    assign(socket, :form, to_form(changeset))
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end

