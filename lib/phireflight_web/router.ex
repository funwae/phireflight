defmodule PhireFlightWeb.Router do
  use PhireFlightWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {PhireFlightWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", PhireFlightWeb do
    pipe_through :browser

    get "/", PageController, :home
  end

  # API routes for trace ingestion
  scope "/api", PhireFlightWeb.API do
    pipe_through :api

    # Will be implemented in later phases
    # post "/traces", TraceController, :create
    # post "/events", EventController, :create
  end

  if Application.compile_env(:phireflight, :dev_routes) do
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: PhireFlightWeb.Telemetry
    end
  end
end
