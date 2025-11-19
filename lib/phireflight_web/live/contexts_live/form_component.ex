defmodule PhireFlightWeb.ContextsLive.FormComponent do
  use PhireFlightWeb, :live_component

  alias PhireFlight.Contexts

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        <%= @title %>
        <:subtitle>Define a bounded context for <%= @app.name %></:subtitle>
      </.header>

      <.simple_form
        for={@form}
        id="context-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.input field={@form[:name]} type="text" label="Name" required />
        <.input field={@form[:full_name]} type="text" label="Full Name (Module Path)" />
        <.input field={@form[:description]} type="textarea" label="Description" />
        <.input
          field={@form[:kind]}
          type="select"
          label="Kind"
          options={[Domain: :domain, Integration: :integration, UI: :ui, Infrastructure: :infra]}
        />
        <.input field={@form[:color]} type="text" label="Color (Hex)" placeholder="#3B82F6" />
        <:actions>
          <.button phx-disable-with="Saving...">Save Context</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(%{app_context: app_context} = assigns, socket) do
    changeset = Contexts.change_app_context(app_context)

    {:ok,
     socket
     |> assign(assigns)
     |> assign_form(changeset)}
  end

  @impl true
  def handle_event("validate", %{"app_context" => app_context_params}, socket) do
    changeset =
      socket.assigns.app_context
      |> Contexts.change_app_context(app_context_params)
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset)}
  end

  def handle_event("save", %{"app_context" => app_context_params}, socket) do
    save_context(socket, socket.assigns.action, app_context_params)
  end

  defp save_context(socket, :edit, app_context_params) do
    case Contexts.update_app_context(socket.assigns.app_context, app_context_params) do
      {:ok, app_context} ->
        notify_parent({:saved, app_context})

        {:noreply,
         socket
         |> put_flash(:info, "Context updated successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp save_context(socket, :new, app_context_params) do
    app_context_params = Map.put(app_context_params, "app_id", socket.assigns.app.id)

    case Contexts.create_app_context(app_context_params) do
      {:ok, app_context} ->
        notify_parent({:saved, app_context})

        {:noreply,
         socket
         |> put_flash(:info, "Context created successfully")
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

