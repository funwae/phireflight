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
      @status == :ok && "bg-green-500/20 text-green-400 border border-green-500/30",
      @status == :error && "bg-red-500/20 text-red-400 border border-red-500/30",
      @status == :timeout && "bg-yellow-500/20 text-yellow-400 border border-yellow-500/30",
      @status == :cancelled && "bg-slate-700 text-slate-300 border border-slate-600"
    ]}>
      <%= String.capitalize(to_string(@status)) %>
    </span>
    """
  end
end

