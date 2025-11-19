defmodule PhireFlightWeb.FlightDiagramComponent do
  @moduledoc """
  Component for rendering the context flow diagram in flight replay.
  """
  use PhireFlightWeb, :live_component

  attr :context_flow, :list, required: true
  attr :events, :list, required: true
  attr :selected_event_id, :string, default: nil

  def render(assigns) do
    ~H"""
    <div class="bg-slate-900 rounded-xl p-6 border border-slate-800">
      <h3 class="text-lg font-semibold text-slate-100 mb-4">Context Flow</h3>
      <div class="space-y-4">
        <%= if length(@context_flow) > 0 do %>
          <div class="flex flex-wrap gap-3">
            <%= for {context, count} <- @context_flow do %>
              <div
                class={[
                  "px-4 py-3 rounded-lg border-2 transition-all",
                  if(@selected_event_id && event_in_context?(@events, @selected_event_id, context.id),
                    do: "ring-2 ring-orange-500 bg-orange-500/20",
                    else: "border-slate-700 bg-slate-800"
                  )
                ]}
                style={"border-color: #{context.color || '#3B82F6'}"}
                phx-click="select_context"
                phx-value-context_id={context.id}
                phx-target={@myself}
              >
                <div class="flex items-center gap-2 mb-1">
                  <div class="w-2 h-2 rounded-full" style={"background-color: #{context.color || '#3B82F6'}"}></div>
                  <div class="font-semibold text-slate-100"><%= context.name %></div>
                </div>
                <div class="text-xs text-slate-400"><%= count %> flight steps</div>
              </div>
            <% end %>
          </div>
        <% else %>
          <p class="text-slate-400">No context flow data available.</p>
        <% end %>
      </div>
    </div>
    """
  end

  defp event_in_context?(events, event_id, context_id) do
    event = Enum.find(events, &(&1.id == event_id))
    event && event.app_context_id == context_id
  end

  def handle_event("select_context", %{"context_id" => context_id}, socket) do
    send(self(), {:select_context, context_id})
    {:noreply, socket}
  end
end

