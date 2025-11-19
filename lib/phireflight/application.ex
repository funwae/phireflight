defmodule PhireFlight.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      PhireFlightWeb.Telemetry,
      PhireFlight.Repo,
      {DNSCluster, query: Application.get_env(:phireflight, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: PhireFlight.PubSub},
      {Finch, name: PhireFlight.Finch},
      PhireFlightWeb.Endpoint
    ]

    opts = [strategy: :one_for_one, name: PhireFlight.Supervisor]
    Supervisor.start_link(children, opts)
  end

  @impl true
  def config_change(changed, _new, removed) do
    PhireFlightWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
