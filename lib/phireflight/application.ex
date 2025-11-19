defmodule PhireFlight.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      PhireFlightWeb.Telemetry,
      PhireFlight.Repo,
      {DNSCluster, query: Application.get_env(:phireflight, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: PhireFlight.PubSub},
      # Start the Finch HTTP client for sending emails
      {Finch, name: PhireFlight.Finch},
      # Start a worker by calling: PhireFlight.Worker.start_link(arg)
      # {PhireFlight.Worker, arg},
      # Start to serve requests, typically the last entry
      PhireFlightWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: PhireFlight.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    PhireFlightWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
