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

  # Public routes
  scope "/", PhireFlightWeb do
    pipe_through :browser

    get "/", PageController, :home
  end

  # API routes for trace ingestion
  # Will be implemented in Phase 4 (Instrumentation Client)
  scope "/api", PhireFlightWeb.API do
    pipe_through :api

    # post "/traces", TraceController, :create
    # post "/events", EventController, :create
  end

  # LiveView routes (Phase 3 - Basic LiveView UI)
  # Note: Authentication will be added later
  scope "/", PhireFlightWeb do
    pipe_through :browser

    live "/apps", AppsLive.Index, :index
    live "/apps/new", AppsLive.Index, :new
    live "/apps/:id/edit", AppsLive.Index, :edit
    live "/apps/:id", AppsLive.Show, :show

    live "/apps/:app_id/contexts", ContextsLive.Index, :index
    live "/apps/:app_id/contexts/new", ContextsLive.Index, :new
    live "/apps/:app_id/contexts/:id/edit", ContextsLive.Index, :edit

    live "/apps/:app_id/traces", TracesLive.Index, :index
    live "/apps/:app_id/traces/:id", TracesLive.Show, :show
  end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:phireflight, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: PhireFlightWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end
end
