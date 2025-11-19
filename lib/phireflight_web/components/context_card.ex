defmodule PhireFlightWeb.Components.ContextCard do
  @moduledoc """
  Context card component for displaying app contexts.
  """
  use Phoenix.Component

  attr :context, :map, required: true

  def context_card(assigns) do
    ~H"""
    <div
      class="p-4 rounded-lg border-2 hover:border-slate-700 transition-colors bg-slate-900 border-slate-800"
      style={@context.color && "border-color: #{@context.color}"}
      title={@context.description || @context.full_name}
    >
      <div class="flex items-start justify-between mb-2">
        <div class="flex items-center gap-2">
          <div class="w-2 h-2 rounded-full" style={"background-color: #{@context.color || '#3B82F6'}"}></div>
          <h3 class="font-semibold text-lg text-slate-100"><%= @context.name %></h3>
        </div>
        <.kind_badge kind={@context.kind} />
      </div>
      <%= if @context.description do %>
        <p class="text-sm text-slate-400"><%= @context.description %></p>
      <% end %>
      <%= if @context.full_name do %>
        <p class="text-xs text-slate-500 mt-1 font-mono"><%= @context.full_name %></p>
      <% end %>
    </div>
    """
  end

  defp kind_badge(assigns) do
    ~H"""
    <span class={[
      "text-xs px-2 py-1 rounded",
      @kind == :domain && "bg-blue-500/20 text-blue-400 border border-blue-500/30",
      @kind == :integration && "bg-purple-500/20 text-purple-400 border border-purple-500/30",
      @kind == :ui && "bg-green-500/20 text-green-400 border border-green-500/30",
      @kind == :infra && "bg-slate-700 text-slate-300 border border-slate-600"
    ]}>
      <%= String.capitalize(to_string(@kind)) %>
    </span>
    """
  end
end

