defmodule PhireFlight.Instrumentation.PlugTest do
  use PhireFlightWeb.ConnCase

  alias PhireFlight.Instrumentation.Plug
  alias PhireFlight.{Apps, Accounts, Traces}

  setup do
    # Create test user and app
    {:ok, user} = Accounts.register_user(%{
      email: "test@example.com",
      password: "password123456",
      name: "Test User"
    })

    {:ok, app} = Apps.create_app(%{
      name: "Test App",
      slug: "test-app",
      owner_id: user.id
    })

    opts = Plug.init(app_slug: app.slug)
    %{app: app, opts: opts}
  end

  test "starts trace on request", %{opts: opts} do
    conn =
      :get
      |> build_conn("/test")
      |> Plug.call(opts)

    assert conn.private[:phireflight_trace_id] != nil

    # Verify trace was created
    trace_id = conn.private[:phireflight_trace_id]
    trace = Traces.get_trace!(trace_id)
    assert trace.entry_point == "GET /test"
    assert trace.request_method == "GET"
    assert trace.request_path == "/test"
  end

  test "finishes trace with ok status on success", %{opts: opts} do
    conn =
      :get
      |> build_conn("/test")
      |> Plug.call(opts)
      |> send_resp(200, "OK")

    trace_id = conn.private[:phireflight_trace_id]
    trace = Traces.get_trace!(trace_id)
    assert trace.status == :ok
    assert trace.finished_at != nil
  end

  test "finishes trace with error status on 5xx", %{opts: opts} do
    conn =
      :get
      |> build_conn("/test")
      |> Plug.call(opts)
      |> send_resp(500, "Error")

    trace_id = conn.private[:phireflight_trace_id]
    trace = Traces.get_trace!(trace_id)
    assert trace.status == :error
    assert trace.error_class == "HTTPError"
  end

  test "includes params in metadata when enabled", %{app: app} do
    opts = Plug.init(app_slug: app.slug, include_params: true)

    conn =
      :get
      |> build_conn("/test?foo=bar")
      |> Plug.call(opts)

    trace_id = conn.private[:phireflight_trace_id]
    trace = Traces.get_trace!(trace_id)
    assert trace.metadata[:params] != nil
  end

  test "includes headers in metadata when enabled", %{app: app} do
    opts = Plug.init(app_slug: app.slug, include_headers: true)

    conn =
      :get
      |> build_conn("/test")
      |> put_req_header("x-custom", "value")
      |> Plug.call(opts)

    trace_id = conn.private[:phireflight_trace_id]
    trace = Traces.get_trace!(trace_id)
    assert trace.metadata[:headers] != nil
  end
end

