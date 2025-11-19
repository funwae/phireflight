defmodule DemoShop.Billing do
  @moduledoc """
  The Billing context - handles payments.
  """

  alias PhireFlight.Instrumentation.Client
  alias DemoShop.Repo
  alias DemoShop.Billing.Payment

  @doc """
  Charges an order (mock Stripe integration).
  """
  def charge_order(order, payment_method) do
    Client.trace_function("DemoShop.Billing", "charge_order", 2, fn ->
      # Simulate Stripe charge
      external_id = "ch_#{:rand.uniform(999999)}"

      payment_attrs = %{
        order_id: order.id,
        amount_cents: order.total_cents,
        payment_method: payment_method,
        external_id: external_id,
        status: :succeeded  # Always succeed in demo
      }

      %Payment{}
      |> Payment.changeset(payment_attrs)
      |> Repo.insert()
    end)
  end

  @doc """
  Gets a payment for an order.
  """
  def get_payment_for_order(order_id) do
    Client.trace_function("DemoShop.Billing", "get_payment_for_order", 1, fn ->
      Repo.get_by(Payment, order_id: order_id)
    end)
  end
end

