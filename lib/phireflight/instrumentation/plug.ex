defmodule PhireFlight.Instrumentation.Plug do
  @moduledoc """
  Plug to automatically trace Phoenix HTTP requests.

  ## Usage

  In your endpoint or router:

      plug PhireFlight.Instrumentation.Plug, app_slug: "demo-shop"

  ## Options

    * `:app_slug` - The slug of the app in PhireFlight (required)
    * `:include_params` - Include request params in metadata (default: false)
    * `:include_headers` - Include request headers in metadata (default: false)
  """

  import Plug.Conn
  alias PhireFlight.Instrumentation.Client
  require Logger

  @behaviour Plug

  @impl true
  def init(opts) do
    app_slug = Keyword.fetch!(opts, :app_slug)

    %{
      app_slug: app_slug,
      include_params: Keyword.get(opts, :include_params, false),
      include_headers: Keyword.get(opts, :include_headers, false)
    }
  end

  @impl true
  def call(conn, opts) do
    entry_point = "#{conn.method} #{conn.request_path}"

    metadata =
      %{}
      |> maybe_put_params(conn, opts[:include_params])
      |> maybe_put_headers(conn, opts[:include_headers])

    case Client.start_trace(%{
           app_slug: opts[:app_slug],
           entry_point: entry_point,
           request_method: conn.method,
           request_path: conn.request_path,
           metadata: metadata
         }) do
      {:ok, trace_id} ->
        Logger.debug("Started trace: #{trace_id}")

        conn
        |> put_private(:phireflight_trace_id, trace_id)
        |> register_before_send(&finish_trace/1)

      {:error, reason} ->
        Logger.error("Failed to start trace: #{inspect(reason)}")
        conn
    end
  end

  defp finish_trace(conn) do
    status =
      cond do
        conn.status >= 200 and conn.status < 400 -> :ok
        conn.status >= 500 -> :error
        true -> :ok
      end

    error_info =
      if status == :error do
        %{
          class: "HTTPError",
          message: "HTTP #{conn.status}"
        }
      end

    Client.finish_trace(status, error_info)
    conn
  end

  defp maybe_put_params(metadata, _conn, false), do: metadata

  defp maybe_put_params(metadata, conn, true) do
    Map.put(metadata, :params, conn.params)
  end

  defp maybe_put_headers(metadata, _conn, false), do: metadata

  defp maybe_put_headers(metadata, conn, true) do
    headers =
      conn.req_headers
      |> Enum.into(%{})

    Map.put(metadata, :headers, headers)
  end
end

