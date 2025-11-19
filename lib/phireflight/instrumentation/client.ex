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
      * `:error` - Boolean flag for errors (optional)
      * `:error_message` - Error message (optional)

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
          |> Map.put_new(:error, false)

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

