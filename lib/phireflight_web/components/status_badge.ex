defmodule PhireFlightWeb.Components.StatusBadge do
  @moduledoc """
  Status badge component for displaying trace status.
  """
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
      <%= String.capitalize(to_string(@status)) %>
    </span>
    """
  end
end

