# PhireFlight Instrumentation Client

## Overview
This document defines the instrumentation client library used to trace Phoenix applications and send events to PhireFlight.

For MVP, the client is embedded in the same repo. Later, it can be extracted as a standalone hex package.

---

## Architecture

### Storage Strategy

The client uses **process dictionary** for trace context storage:
- Lightweight and automatic cleanup when process dies
- Works naturally with Phoenix request lifecycle
- No need for external state management

### Communication Strategy

For MVP (same repo):
- **Direct context calls** - No HTTP overhead
- DemoShop calls `PhireFlight.Traces` and `PhireFlight.TraceEvents` directly

For future (external apps):
- **HTTP API** - POST events to PhireFlight endpoints
- Async with buffering for performance

---

## Module: PhireFlight.Instrumentation.Client

**File:** `lib/phireflight/instrumentation/client.ex`

### Full Implementation

```elixir
defmodule PhireFlight.Instrumentation.Client do
  @moduledoc """
  Client library for instrumenting Phoenix apps to send traces to PhireFlight.

  ## Usage

  In your endpoint or router plug:

      plug PhireFlight.Instrumentation.Plug

  Or manually in your code:

      # Start trace
      {:ok, trace_id} = PhireFlight.Instrumentation.Client.start_trace(%{
        app_slug: "demo-shop",
        entry_point: "GET /checkout",
        request_method: "GET",
        request_path: "/checkout"
      })

      # Record steps
      PhireFlight.Instrumentation.Client.record_step(%{
        module: "DemoShop.Accounts",
        function: "get_user",
        arity: 1,
        event_type: :context_call
      })

      # Finish trace
      PhireFlight.Instrumentation.Client.finish_trace(:ok)
  """

  alias PhireFlight.{Traces, TraceEvents, Apps, Contexts}
  require Logger

  @trace_key {__MODULE__, :trace_id}
  @app_key {__MODULE__, :app_id}
  @event_counter_key {__MODULE__, :event_counter}

  ## Public API

  @doc """
  Starts a new trace for the current process.

  ## Parameters

    * `attrs` - Map with:
      * `:app_slug` - Slug of the app being traced (required)
      * `:entry_point` - Description of entry point (required)
      * `:request_method` - HTTP method (optional)
      * `:request_path` - URL path (optional)
      * `:external_id` - Correlation ID (optional, generated if not provided)
      * `:metadata` - Additional metadata map (optional)

  ## Returns

    * `{:ok, trace_id}` - Trace started successfully
    * `{:error, reason}` - Failed to start trace

  ## Examples

      iex> start_trace(%{
      ...>   app_slug: "demo-shop",
      ...>   entry_point: "GET /products"
      ...> })
      {:ok, "550e8400-e29b-41d4-a716-446655440000"}
  """
  @spec start_trace(map()) :: {:ok, binary()} | {:error, term()}
  def start_trace(attrs) do
    with {:ok, app} <- get_or_find_app(attrs[:app_slug]),
         {:ok, trace} <- create_trace(app.id, attrs) do
      # Store in process dictionary
      Process.put(@trace_key, trace.id)
      Process.put(@app_key, app.id)
      Process.put(@event_counter_key, 0)

      {:ok, trace.id}
    end
  end

  @doc """
  Records a step in the current trace.

  Uses the trace_id stored in the process dictionary.

  ## Parameters

    * `attrs` - Map with:
      * `:module` - Module name (required)
      * `:function` - Function name (required)
      * `:arity` - Function arity (optional)
      * `:event_type` - Event type atom (default: :other)
      * `:context_name` - Context name for auto-discovery (optional)
      * `:metadata` - Additional metadata (optional)
      * `:duration_ms` - Pre-calculated duration (optional)

  ## Returns

    * `:ok` - Event recorded
    * `{:error, reason}` - Failed to record

  ## Examples

      iex> record_step(%{
      ...>   module: "DemoShop.Accounts",
      ...>   function: "create_user",
      ...>   arity: 1,
      ...>   event_type: :context_call,
      ...>   context_name: "Accounts"
      ...> })
      :ok
  """
  @spec record_step(map()) :: :ok | {:error, term()}
  def record_step(attrs) do
    case current_trace_id() do
      nil ->
        Logger.warning("Attempted to record step without active trace")
        {:error, :no_active_trace}

      trace_id ->
        app_id = Process.get(@app_key)
        sequence_index = get_and_increment_counter()

        # Find or create context if context_name provided
        app_context_id =
          if attrs[:context_name] do
            case find_or_create_context(app_id, attrs[:context_name]) do
              {:ok, context} -> context.id
              _ -> nil
            end
          end

        event_attrs =
          attrs
          |> Map.put(:trace_id, trace_id)
          |> Map.put(:app_context_id, app_context_id)
          |> Map.put(:sequence_index, sequence_index)
          |> Map.put_new(:started_at, DateTime.utc_now())
          |> Map.put_new(:event_type, :other)

        case TraceEvents.record_event(event_attrs) do
          {:ok, _event} -> :ok
          {:error, reason} -> {:error, reason}
        end
    end
  end

  @doc """
  Finishes the current trace.

  ## Parameters

    * `status` - Trace status (`:ok`, `:error`, `:timeout`, `:cancelled`)
    * `error_info` - Optional map with `:class` and `:message` for errors

  ## Examples

      iex> finish_trace(:ok)
      :ok

      iex> finish_trace(:error, %{class: "ArgumentError", message: "Invalid user"})
      :ok
  """
  @spec finish_trace(atom(), map() | nil) :: :ok | {:error, term()}
  def finish_trace(status, error_info \\ nil) do
    case current_trace_id() do
      nil ->
        Logger.warning("Attempted to finish trace without active trace")
        {:error, :no_active_trace}

      trace_id ->
        trace = Traces.get_trace!(trace_id)

        finish_attrs =
          %{
            status: status,
            finished_at: DateTime.utc_now()
          }
          |> maybe_put_error_info(error_info)

        case Traces.finish_trace(trace, finish_attrs) do
          {:ok, _trace} ->
            # Clean up process dictionary
            Process.delete(@trace_key)
            Process.delete(@app_key)
            Process.delete(@event_counter_key)
            :ok

          {:error, reason} ->
            {:error, reason}
        end
    end
  end

  @doc """
  Gets the current trace ID from the process dictionary.

  Returns `nil` if no trace is active.
  """
  @spec current_trace_id() :: binary() | nil
  def current_trace_id do
    Process.get(@trace_key)
  end

  @doc """
  Wraps a function with automatic tracing.

  Records the start and finish of the function, including duration and errors.

  ## Examples

      iex> trace_function("DemoShop.Accounts", "create_user", 1, fn ->
      ...>   # Your code here
      ...>   {:ok, user}
      ...> end)
      {:ok, user}
  """
  @spec trace_function(String.t(), String.t(), integer(), function()) :: any()
  def trace_function(module, function, arity, fun) do
    started_at = DateTime.utc_now()

    try do
      result = fun.()

      finished_at = DateTime.utc_now()
      duration_ms = DateTime.diff(finished_at, started_at, :millisecond)

      record_step(%{
        module: module,
        function: function,
        arity: arity,
        event_type: detect_event_type(module),
        started_at: started_at,
        finished_at: finished_at,
        duration_ms: duration_ms,
        context_name: extract_context_name(module)
      })

      result
    rescue
      error ->
        finished_at = DateTime.utc_now()
        duration_ms = DateTime.diff(finished_at, started_at, :millisecond)

        record_step(%{
          module: module,
          function: function,
          arity: arity,
          event_type: detect_event_type(module),
          started_at: started_at,
          finished_at: finished_at,
          duration_ms: duration_ms,
          error: true,
          error_message: Exception.message(error),
          context_name: extract_context_name(module)
        })

        reraise error, __STACKTRACE__
    end
  end

  ## Private Functions

  defp get_or_find_app(slug) when is_binary(slug) do
    case Apps.get_app_by_slug(slug) do
      nil -> {:error, :app_not_found}
      app -> {:ok, app}
    end
  end

  defp get_or_find_app(_), do: {:error, :invalid_app_slug}

  defp create_trace(app_id, attrs) do
    trace_attrs =
      %{
        app_id: app_id,
        entry_point: attrs[:entry_point] || "unknown",
        request_method: attrs[:request_method],
        request_path: attrs[:request_path],
        external_id: attrs[:external_id] || generate_trace_id(),
        started_at: DateTime.utc_now(),
        metadata: attrs[:metadata] || %{}
      }

    Traces.start_trace(trace_attrs)
  end

  defp find_or_create_context(app_id, context_name) do
    Contexts.find_or_create_app_context(app_id, context_name)
  end

  defp get_and_increment_counter do
    current = Process.get(@event_counter_key, 0)
    Process.put(@event_counter_key, current + 1)
    current
  end

  defp maybe_put_error_info(attrs, nil), do: attrs

  defp maybe_put_error_info(attrs, error_info) do
    attrs
    |> Map.put(:error_class, error_info[:class])
    |> Map.put(:error_message, error_info[:message])
  end

  defp detect_event_type(module) when is_binary(module) do
    cond do
      String.ends_with?(module, "Controller") -> :controller
      String.ends_with?(module, "Live") -> :liveview
      String.contains?(module, "Repo") -> :db_query
      true -> :context_call
    end
  end

  defp extract_context_name(module) when is_binary(module) do
    # Extract context name from module
    # e.g. "DemoShop.Accounts.User" -> "Accounts"
    case String.split(module, ".") do
      [_app, context | _rest] -> context
      _ -> nil
    end
  end

  defp generate_trace_id do
    UUID.uuid4()
  end
end
```

---

## Module: PhireFlight.Instrumentation.Plug

**File:** `lib/phireflight/instrumentation/plug.ex`

### Implementation

```elixir
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
```

---

## Module: PhireFlight.Instrumentation.Macro

**File:** `lib/phireflight/instrumentation/macro.ex`

### Implementation (Advanced - Optional)

```elixir
defmodule PhireFlight.Instrumentation.Macro do
  @moduledoc """
  Macros for automatic function tracing.

  ## Usage

      defmodule DemoShop.Accounts do
        use PhireFlight.Instrumentation.Macro

        @trace true
        def create_user(attrs) do
          # This function will be automatically traced
        end

        def some_internal_function do
          # This function will NOT be traced
        end
      end
  """

  defmacro __using__(_opts) do
    quote do
      import PhireFlight.Instrumentation.Macro
      Module.register_attribute(__MODULE__, :trace, accumulate: false)
      @before_compile PhireFlight.Instrumentation.Macro
    end
  end

  defmacro __before_compile__(env) do
    # This would require more complex AST manipulation
    # For MVP, we'll use manual trace_function calls
    # Future: Automatically wrap @trace functions
    quote do
      # Implementation would inject tracing around @trace functions
    end
  end
end
```

---

## DemoShop Integration Example

### In DemoShop Endpoint

**File:** `lib/demo_shop_web/endpoint.ex`

```elixir
defmodule DemoShopWeb.Endpoint do
  use Phoenix.Endpoint, otp_app: :demo_shop

  # ... other plugs ...

  plug PhireFlight.Instrumentation.Plug, app_slug: "demo-shop"

  # ... rest of endpoint ...
end
```

### In DemoShop Context

**File:** `lib/demo_shop/accounts/accounts.ex`

```elixir
defmodule DemoShop.Accounts do
  alias PhireFlight.Instrumentation.Client
  alias DemoShop.Repo
  alias DemoShop.Accounts.User

  def get_user(id) do
    Client.trace_function("DemoShop.Accounts", "get_user", 1, fn ->
      Repo.get(User, id)
    end)
  end

  def create_user(attrs) do
    Client.trace_function("DemoShop.Accounts", "create_user", 1, fn ->
      %User{}
      |> User.changeset(attrs)
      |> Repo.insert()
    end)
  end
end
```

### Alternative: Manual Tracing

```elixir
defmodule DemoShop.Checkout do
  alias PhireFlight.Instrumentation.Client

  def process_checkout(cart) do
    Client.record_step(%{
      module: "DemoShop.Checkout",
      function: "process_checkout",
      arity: 1,
      event_type: :context_call,
      context_name: "Checkout"
    })

    started_at = DateTime.utc_now()

    # Do work
    result = do_checkout(cart)

    finished_at = DateTime.utc_now()
    duration_ms = DateTime.diff(finished_at, started_at, :millisecond)

    # Could update the event with duration if we stored event_id
    # For MVP, duration is less critical

    result
  end
end
```

---

## Future: HTTP Reporter (External Apps)

**File:** `lib/phireflight/instrumentation/http_reporter.ex`

```elixir
defmodule PhireFlight.Instrumentation.HTTPReporter do
  @moduledoc """
  HTTP-based event reporter for external apps.

  Used when PhireFlight is deployed separately and external apps
  send traces via HTTP API.
  """

  use GenServer

  @batch_size 50
  @flush_interval 5_000

  # ... GenServer implementation with batching and retry logic ...

  def report_trace(trace_attrs) do
    # POST to /api/traces
  end

  def report_event(event_attrs) do
    # Add to buffer, batch send
    GenServer.cast(__MODULE__, {:buffer_event, event_attrs})
  end
end
```

---

## Testing Strategy

### Unit Tests

**File:** `test/phireflight/instrumentation/client_test.exs`

```elixir
defmodule PhireFlight.Instrumentation.ClientTest do
  use PhireFlight.DataCase

  alias PhireFlight.Instrumentation.Client
  alias PhireFlight.{Apps, Traces, TraceEvents}

  setup do
    # Create test app
    {:ok, app} = Apps.create_app(%{
      name: "Test App",
      slug: "test-app",
      owner_id: insert(:user).id
    })

    %{app: app}
  end

  describe "start_trace/1" do
    test "starts a new trace and stores trace_id in process dictionary", %{app: app} do
      {:ok, trace_id} = Client.start_trace(%{
        app_slug: app.slug,
        entry_point: "GET /test"
      })

      assert trace_id == Client.current_trace_id()
      assert Traces.get_trace!(trace_id)
    end

    test "returns error for unknown app" do
      assert {:error, :app_not_found} = Client.start_trace(%{
        app_slug: "nonexistent",
        entry_point: "GET /test"
      })
    end
  end

  describe "record_step/1" do
    setup %{app: app} do
      {:ok, trace_id} = Client.start_trace(%{
        app_slug: app.slug,
        entry_point: "GET /test"
      })

      %{trace_id: trace_id}
    end

    test "records an event in the current trace", %{trace_id: trace_id} do
      :ok = Client.record_step(%{
        module: "TestApp.Accounts",
        function: "get_user",
        arity: 1,
        event_type: :context_call
      })

      events = TraceEvents.list_trace_events(trace_id)
      assert length(events) == 1
      assert hd(events).module == "TestApp.Accounts"
    end
  end

  describe "trace_function/4" do
    setup %{app: app} do
      {:ok, _trace_id} = Client.start_trace(%{
        app_slug: app.slug,
        entry_point: "GET /test"
      })

      :ok
    end

    test "traces a successful function call" do
      result = Client.trace_function("TestApp", "test_fn", 0, fn ->
        :ok
      end)

      assert result == :ok
      events = TraceEvents.list_trace_events(Client.current_trace_id())
      assert length(events) == 1
    end

    test "traces a function that raises" do
      assert_raise RuntimeError, fn ->
        Client.trace_function("TestApp", "test_fn", 0, fn ->
          raise "test error"
        end)
      end

      events = TraceEvents.list_trace_events(Client.current_trace_id())
      assert length(events) == 1
      assert hd(events).error == true
    end
  end
end
```

---

## Summary

**Instrumentation Client Features:**

- ✅ **Process-based storage** - Automatic cleanup, no state management
- ✅ **Plug integration** - Automatic HTTP request tracing
- ✅ **Manual tracing** - `trace_function/4` wrapper
- ✅ **Context auto-discovery** - Finds or creates contexts from module names
- ✅ **Error tracking** - Captures exceptions and status
- ✅ **Metadata support** - Flexible additional data
- ✅ **Sequence tracking** - Auto-incrementing event indexes
- 🔮 **Future: Macro-based** - `@trace` attribute for automatic instrumentation
- 🔮 **Future: HTTP reporter** - For external apps with batching and retry

**DemoShop will use:**
- Plug for HTTP requests
- Manual `trace_function` calls in key context functions
- Shows clear before/after for instrumentation
