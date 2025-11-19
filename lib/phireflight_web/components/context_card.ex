defmodule PhireFlightWeb.Components.ContextCard do
  @moduledoc """
  Context card component for displaying app contexts.
  """
  use Phoenix.Component

  attr :context, :map, required: true

  def context_card(assigns) do
    ~H"""
    <div
      class="p-4 rounded-lg border-2 hover:shadow-lg transition-shadow bg-white dark:bg-gray-800"
      style={@context.color && "border-color: #{@context.color}"}
    >
      <div class="flex items-start justify-between mb-2">
        <h3 class="font-semibold text-lg"><%= @context.name %></h3>
        <.kind_badge kind={@context.kind} />
      </div>
      <%= if @context.description do %>
        <p class="text-sm text-gray-600 dark:text-gray-400"><%= @context.description %></p>
      <% end %>
      <%= if @context.full_name do %>
        <p class="text-xs text-gray-500 dark:text-gray-500 mt-1 font-mono"><%= @context.full_name %></p>
      <% end %>
    </div>
    """
  end

  defp kind_badge(assigns) do
    ~H"""
    <span class={[
      "text-xs px-2 py-1 rounded",
      @kind == :domain && "bg-blue-100 text-blue-800 dark:bg-blue-800 dark:text-blue-100",
      @kind == :integration && "bg-purple-100 text-purple-800 dark:bg-purple-800 dark:text-purple-100",
      @kind == :ui && "bg-green-100 text-green-800 dark:bg-green-800 dark:text-green-100",
      @kind == :infra && "bg-gray-100 text-gray-800 dark:bg-gray-800 dark:text-gray-100"
    ]}>
      <%= String.capitalize(to_string(@kind)) %>
    </span>
    """
  end
end

