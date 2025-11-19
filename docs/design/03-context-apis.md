# PhireFlight Context APIs

## Overview
This document defines the public API for each Phoenix context, including function signatures, documentation, and usage examples.

---

## PhireFlight.Accounts

**File:** `lib/phireflight/accounts/accounts.ex`

### Public API

```elixir
defmodule PhireFlight.Accounts do
  @moduledoc """
  The Accounts context manages users and authentication.
  """

  alias PhireFlight.Accounts.{User, UserToken}
  alias PhireFlight.Repo

  ## User registration

  @doc """
  Registers a new user.

  ## Examples

      iex> register_user(%{email: "user@example.com", password: "validpassword123"})
      {:ok, %User{}}

      iex> register_user(%{email: "invalid", password: "short"})
      {:error, %Ecto.Changeset{}}
  """
  @spec register_user(map()) :: {:ok, User.t()} | {:error, Ecto.Changeset.t()}
  def register_user(attrs)

  ## User retrieval

  @doc """
  Gets a single user by ID.

  Raises `Ecto.NoResultsError` if the User does not exist.
  """
  @spec get_user!(binary()) :: User.t()
  def get_user!(id)

  @doc """
  Gets a user by email.
  """
  @spec get_user_by_email(String.t()) :: User.t() | nil
  def get_user_by_email(email)

  @doc """
  Gets a user by email and password.
  """
  @spec get_user_by_email_and_password(String.t(), String.t()) ::
          {:ok, User.t()} | {:error, :unauthorized}
  def get_user_by_email_and_password(email, password)

  ## User updates

  @doc """
  Updates a user's profile.
  """
  @spec update_user(User.t(), map()) :: {:ok, User.t()} | {:error, Ecto.Changeset.t()}
  def update_user(user, attrs)

  @doc """
  Updates a user's password.
  """
  @spec update_user_password(User.t(), String.t(), map()) ::
          {:ok, User.t()} | {:error, Ecto.Changeset.t()}
  def update_user_password(user, current_password, attrs)

  ## Session tokens

  @doc """
  Generates a session token for a user.
  """
  @spec generate_user_session_token(User.t()) :: String.t()
  def generate_user_session_token(user)

  @doc """
  Gets the user with the given signed token.
  """
  @spec get_user_by_session_token(String.t()) :: User.t() | nil
  def get_user_by_session_token(token)

  @doc """
  Deletes a session token.
  """
  @spec delete_user_session_token(String.t()) :: :ok
  def delete_user_session_token(token)
end
```

---

## PhireFlight.Apps

**File:** `lib/phireflight/apps/apps.ex`

### Public API

```elixir
defmodule PhireFlight.Apps do
  @moduledoc """
  The Apps context manages observed Phoenix applications.
  """

  alias PhireFlight.Apps.App
  alias PhireFlight.Repo

  @doc """
  Returns the list of apps for a given user.

  ## Examples

      iex> list_apps(user_id)
      [%App{}, ...]
  """
  @spec list_apps(binary()) :: [App.t()]
  def list_apps(owner_id)

  @doc """
  Returns all apps (admin function).
  """
  @spec list_all_apps() :: [App.t()]
  def list_all_apps()

  @doc """
  Gets a single app.

  Raises `Ecto.NoResultsError` if the App does not exist.
  """
  @spec get_app!(binary()) :: App.t()
  def get_app!(id)

  @doc """
  Gets an app by slug.
  """
  @spec get_app_by_slug(String.t()) :: App.t() | nil
  def get_app_by_slug(slug)

  @doc """
  Gets an app by API key (for instrumentation authentication).
  """
  @spec get_app_by_api_key(String.t()) :: App.t() | nil
  def get_app_by_api_key(api_key)

  @doc """
  Creates an app.

  ## Examples

      iex> create_app(%{name: "MyApp", slug: "myapp", owner_id: user_id})
      {:ok, %App{}}

      iex> create_app(%{name: nil})
      {:error, %Ecto.Changeset{}}
  """
  @spec create_app(map()) :: {:ok, App.t()} | {:error, Ecto.Changeset.t()}
  def create_app(attrs)

  @doc """
  Updates an app.
  """
  @spec update_app(App.t(), map()) :: {:ok, App.t()} | {:error, Ecto.Changeset.t()}
  def update_app(app, attrs)

  @doc """
  Deletes an app.
  """
  @spec delete_app(App.t()) :: {:ok, App.t()} | {:error, Ecto.Changeset.t()}
  def delete_app(app)

  @doc """
  Regenerates the API key for an app.
  """
  @spec regenerate_api_key(App.t()) :: {:ok, App.t()} | {:error, Ecto.Changeset.t()}
  def regenerate_api_key(app)

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking app changes.
  """
  @spec change_app(App.t(), map()) :: Ecto.Changeset.t()
  def change_app(app, attrs \\ %{})
end
```

---

## PhireFlight.Contexts

**File:** `lib/phireflight/contexts/contexts.ex`

### Public API

```elixir
defmodule PhireFlight.Contexts do
  @moduledoc """
  The Contexts context manages logical contexts within observed apps.
  """

  alias PhireFlight.Contexts.AppContext
  alias PhireFlight.Repo

  @doc """
  Returns the list of contexts for a given app.

  ## Examples

      iex> list_app_contexts(app_id)
      [%AppContext{}, ...]
  """
  @spec list_app_contexts(binary()) :: [AppContext.t()]
  def list_app_contexts(app_id)

  @doc """
  Gets a single app context.

  Raises `Ecto.NoResultsError` if the AppContext does not exist.
  """
  @spec get_app_context!(binary()) :: AppContext.t()
  def get_app_context!(id)

  @doc """
  Gets an app context by app_id and name.
  """
  @spec get_app_context_by_name(binary(), String.t()) :: AppContext.t() | nil
  def get_app_context_by_name(app_id, name)

  @doc """
  Finds or creates an app context by name.
  Useful during trace ingestion when contexts are auto-discovered.
  """
  @spec find_or_create_app_context(binary(), String.t(), map()) ::
          {:ok, AppContext.t()} | {:error, Ecto.Changeset.t()}
  def find_or_create_app_context(app_id, name, attrs \\ %{})

  @doc """
  Creates an app context.

  ## Examples

      iex> create_app_context(%{app_id: app_id, name: "Accounts"})
      {:ok, %AppContext{}}
  """
  @spec create_app_context(map()) :: {:ok, AppContext.t()} | {:error, Ecto.Changeset.t()}
  def create_app_context(attrs)

  @doc """
  Updates an app context.
  """
  @spec update_app_context(AppContext.t(), map()) ::
          {:ok, AppContext.t()} | {:error, Ecto.Changeset.t()}
  def update_app_context(app_context, attrs)

  @doc """
  Deletes an app context.
  """
  @spec delete_app_context(AppContext.t()) ::
          {:ok, AppContext.t()} | {:error, Ecto.Changeset.t()}
  def delete_app_context(app_context)

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking app context changes.
  """
  @spec change_app_context(AppContext.t(), map()) :: Ecto.Changeset.t()
  def change_app_context(app_context, attrs \\ %{})
end
```

---

## PhireFlight.Traces

**File:** `lib/phireflight/traces/traces.ex`

### Public API

```elixir
defmodule PhireFlight.Traces do
  @moduledoc """
  The Traces context manages trace recordings (flights).
  """

  alias PhireFlight.Traces.Trace
  alias PhireFlight.TraceEvents.TraceEvent
  alias PhireFlight.Repo
  import Ecto.Query

  @doc """
  Returns the list of recent traces for an app.

  ## Options

    * `:limit` - Maximum number of traces to return (default: 50)
    * `:offset` - Number of traces to skip (default: 0)
    * `:status` - Filter by status (:ok, :error, etc.)

  ## Examples

      iex> list_traces(app_id, limit: 10)
      [%Trace{}, ...]
  """
  @spec list_traces(binary(), keyword()) :: [Trace.t()]
  def list_traces(app_id, opts \\ [])

  @doc """
  Returns all traces (admin function).
  """
  @spec list_all_traces(keyword()) :: [Trace.t()]
  def list_all_traces(opts \\ [])

  @doc """
  Gets a single trace with preloaded events.

  Raises `Ecto.NoResultsError` if the Trace does not exist.
  """
  @spec get_trace!(binary()) :: Trace.t()
  def get_trace!(id)

  @doc """
  Gets a trace with all events and contexts preloaded.
  """
  @spec get_trace_with_events!(binary()) :: Trace.t()
  def get_trace_with_events!(id)

  @doc """
  Gets a trace by external ID.
  """
  @spec get_trace_by_external_id(binary(), String.t()) :: Trace.t() | nil
  def get_trace_by_external_id(app_id, external_id)

  @doc """
  Starts a new trace.

  ## Examples

      iex> start_trace(%{
      ...>   app_id: app_id,
      ...>   entry_point: "GET /checkout",
      ...>   request_method: "GET",
      ...>   request_path: "/checkout",
      ...>   started_at: DateTime.utc_now()
      ...> })
      {:ok, %Trace{}}
  """
  @spec start_trace(map()) :: {:ok, Trace.t()} | {:error, Ecto.Changeset.t()}
  def start_trace(attrs)

  @doc """
  Finishes a trace with final status and timing.

  ## Examples

      iex> finish_trace(trace, %{
      ...>   status: :ok,
      ...>   finished_at: DateTime.utc_now()
      ...> })
      {:ok, %Trace{}}
  """
  @spec finish_trace(Trace.t(), map()) :: {:ok, Trace.t()} | {:error, Ecto.Changeset.t()}
  def finish_trace(trace, attrs)

  @doc """
  Updates a trace.
  """
  @spec update_trace(Trace.t(), map()) :: {:ok, Trace.t()} | {:error, Ecto.Changeset.t()}
  def update_trace(trace, attrs)

  @doc """
  Deletes a trace and all its events.
  """
  @spec delete_trace(Trace.t()) :: {:ok, Trace.t()} | {:error, Ecto.Changeset.t()}
  def delete_trace(trace)

  @doc """
  Returns statistics for an app's traces.

  Returns a map with:
    * :total_count
    * :ok_count
    * :error_count
    * :avg_duration_ms
  """
  @spec get_trace_stats(binary()) :: map()
  def get_trace_stats(app_id)

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking trace changes.
  """
  @spec change_trace(Trace.t(), map()) :: Ecto.Changeset.t()
  def change_trace(trace, attrs \\ %{})
end
```

---

## PhireFlight.TraceEvents

**File:** `lib/phireflight/trace_events/trace_events.ex`

### Public API

```elixir
defmodule PhireFlight.TraceEvents do
  @moduledoc """
  The TraceEvents context manages individual steps within traces.
  """

  alias PhireFlight.TraceEvents.TraceEvent
  alias PhireFlight.Repo

  @doc """
  Returns the list of events for a trace, ordered by sequence_index.

  ## Examples

      iex> list_trace_events(trace_id)
      [%TraceEvent{}, ...]
  """
  @spec list_trace_events(binary()) :: [TraceEvent.t()]
  def list_trace_events(trace_id)

  @doc """
  Gets a single trace event.

  Raises `Ecto.NoResultsError` if the TraceEvent does not exist.
  """
  @spec get_trace_event!(binary()) :: TraceEvent.t()
  def get_trace_event!(id)

  @doc """
  Records a new trace event.

  Automatically increments sequence_index if not provided.

  ## Examples

      iex> record_event(%{
      ...>   trace_id: trace_id,
      ...>   module: "DemoShop.Accounts",
      ...>   function: "create_user",
      ...>   event_type: :context_call,
      ...>   started_at: DateTime.utc_now()
      ...> })
      {:ok, %TraceEvent{}}
  """
  @spec record_event(map()) :: {:ok, TraceEvent.t()} | {:error, Ecto.Changeset.t()}
  def record_event(attrs)

  @doc """
  Records multiple events in a batch.
  """
  @spec record_events([map()]) :: {:ok, [TraceEvent.t()]} | {:error, term()}
  def record_events(events_attrs)

  @doc """
  Updates a trace event (e.g., to set finished_at and duration).
  """
  @spec update_trace_event(TraceEvent.t(), map()) ::
          {:ok, TraceEvent.t()} | {:error, Ecto.Changeset.t()}
  def update_trace_event(event, attrs)

  @doc """
  Gets the context flow for a trace (ordered unique contexts touched).

  Returns a list of {context, event_count} tuples.
  """
  @spec get_context_flow(binary()) :: [{AppContext.t(), integer()}]
  def get_context_flow(trace_id)

  @doc """
  Gets context transitions (edges) for a trace.

  Returns a list of {from_context, to_context, count} tuples.
  """
  @spec get_context_transitions(binary()) ::
          [{AppContext.t() | nil, AppContext.t() | nil, integer()}]
  def get_context_transitions(trace_id)

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking trace event changes.
  """
  @spec change_trace_event(TraceEvent.t(), map()) :: Ecto.Changeset.t()
  def change_trace_event(event, attrs \\ %{})
end
```

---

## PhireFlight.Visualizations

**File:** `lib/phireflight/visualizations/visualizations.ex`

### Public API

```elixir
defmodule PhireFlight.Visualizations do
  @moduledoc """
  The Visualizations context manages diagram layouts.
  """

  alias PhireFlight.Visualizations.VisualizationLayout
  alias PhireFlight.Repo

  @doc """
  Returns the list of layouts for an app.

  ## Examples

      iex> list_layouts(app_id)
      [%VisualizationLayout{}, ...]
  """
  @spec list_layouts(binary()) :: [VisualizationLayout.t()]
  def list_layouts(app_id)

  @doc """
  Gets a single layout.

  Raises `Ecto.NoResultsError` if the Layout does not exist.
  """
  @spec get_layout!(binary()) :: VisualizationLayout.t()
  def get_layout!(id)

  @doc """
  Gets the default layout for an app and user.

  Falls back to app default if no user-specific layout exists.
  """
  @spec get_default_layout(binary(), binary() | nil) :: VisualizationLayout.t() | nil
  def get_default_layout(app_id, user_id \\ nil)

  @doc """
  Creates a layout.

  ## Examples

      iex> create_layout(%{
      ...>   app_id: app_id,
      ...>   name: "My Layout",
      ...>   layout_json: %{nodes: [...]}
      ...> })
      {:ok, %VisualizationLayout{}}
  """
  @spec create_layout(map()) :: {:ok, VisualizationLayout.t()} | {:error, Ecto.Changeset.t()}
  def create_layout(attrs)

  @doc """
  Updates a layout.
  """
  @spec update_layout(VisualizationLayout.t(), map()) ::
          {:ok, VisualizationLayout.t()} | {:error, Ecto.Changeset.t()}
  def update_layout(layout, attrs)

  @doc """
  Deletes a layout.
  """
  @spec delete_layout(VisualizationLayout.t()) ::
          {:ok, VisualizationLayout.t()} | {:error, Ecto.Changeset.t()}
  def delete_layout(layout)

  @doc """
  Generates an automatic layout for an app's contexts.

  Uses a simple force-directed or hierarchical algorithm.
  """
  @spec generate_auto_layout(binary()) :: map()
  def generate_auto_layout(app_id)

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking layout changes.
  """
  @spec change_layout(VisualizationLayout.t(), map()) :: Ecto.Changeset.t()
  def change_layout(layout, attrs \\ %{})
end
```

---

## PhireFlight.Narrations

**File:** `lib/phireflight/narrations/narrations.ex`

### Public API

```elixir
defmodule PhireFlight.Narrations do
  @moduledoc """
  The Narrations context manages AI-generated trace explanations.
  """

  alias PhireFlight.Narrations.{Narration, Generator}
  alias PhireFlight.Repo

  @doc """
  Gets the narration for a trace.
  """
  @spec get_narration_by_trace_id(binary()) :: Narration.t() | nil
  def get_narration_by_trace_id(trace_id)

  @doc """
  Generates a narration for a trace using an LLM.

  Returns `{:ok, narration}` if successful, or `{:error, reason}` if generation fails.

  ## Options

    * `:model` - LLM model to use (default: from config)
    * `:regenerate` - Force regeneration even if narration exists (default: false)

  ## Examples

      iex> generate_for_trace(trace_id)
      {:ok, %Narration{summary: "This trace...", issues: [...]}}
  """
  @spec generate_for_trace(binary(), keyword()) ::
          {:ok, Narration.t()} | {:error, term()}
  def generate_for_trace(trace_id, opts \\ [])

  @doc """
  Creates a narration manually.
  """
  @spec create_narration(map()) :: {:ok, Narration.t()} | {:error, Ecto.Changeset.t()}
  def create_narration(attrs)

  @doc """
  Updates a narration.
  """
  @spec update_narration(Narration.t(), map()) ::
          {:ok, Narration.t()} | {:error, Ecto.Changeset.t()}
  def update_narration(narration, attrs)

  @doc """
  Deletes a narration.
  """
  @spec delete_narration(Narration.t()) ::
          {:ok, Narration.t()} | {:error, Ecto.Changeset.t()}
  def delete_narration(narration)

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking narration changes.
  """
  @spec change_narration(Narration.t(), map()) :: Ecto.Changeset.t()
  def change_narration(narration, attrs \\ %{})
end
```

---

## PhireFlight.LLMClient

**File:** `lib/phireflight/llm_client/behaviour.ex`

### Behaviour Definition

```elixir
defmodule PhireFlight.LLMClient.Behaviour do
  @moduledoc """
  Behaviour for LLM provider implementations.
  """

  @type message :: %{role: String.t(), content: String.t()}
  @type options :: keyword()
  @type response :: %{
          content: String.t(),
          model: String.t(),
          usage: %{
            input_tokens: integer(),
            output_tokens: integer()
          }
        }

  @doc """
  Sends a completion request to the LLM.

  ## Parameters

    * `messages` - List of message maps with :role and :content
    * `opts` - Options like :model, :temperature, :max_tokens

  ## Returns

    * `{:ok, response}` - Successful completion
    * `{:error, reason}` - Error occurred
  """
  @callback complete(messages :: [message()], opts :: options()) ::
              {:ok, response()} | {:error, term()}
end
```

### Main Module

**File:** `lib/phireflight/llm_client/llm_client.ex`

```elixir
defmodule PhireFlight.LLMClient do
  @moduledoc """
  Main LLM client that delegates to configured provider.
  """

  @doc """
  Sends a completion request using the configured provider.
  """
  @spec complete([map()], keyword()) :: {:ok, map()} | {:error, term()}
  def complete(messages, opts \\ []) do
    provider().complete(messages, opts)
  end

  defp provider do
    Application.get_env(:phireflight, :llm_provider, PhireFlight.LLMClient.Mock)
  end
end
```

---

## PhireFlight.Instrumentation

**File:** `lib/phireflight/instrumentation/client.ex`

### Public API

```elixir
defmodule PhireFlight.Instrumentation.Client do
  @moduledoc """
  Client library for instrumenting Phoenix apps to send traces to PhireFlight.
  """

  alias PhireFlight.{Traces, TraceEvents, Apps, Contexts}

  @doc """
  Starts a new trace.

  Stores the trace_id in the process dictionary for convenience.

  ## Examples

      iex> start_trace(%{
      ...>   app_slug: "demo-shop",
      ...>   entry_point: "GET /checkout",
      ...>   request_method: "GET",
      ...>   request_path: "/checkout"
      ...> })
      {:ok, trace_id}
  """
  @spec start_trace(map()) :: {:ok, binary()} | {:error, term()}
  def start_trace(attrs)

  @doc """
  Records a step in the current trace.

  ## Examples

      iex> record_step(%{
      ...>   module: "DemoShop.Accounts",
      ...>   function: "get_user",
      ...>   arity: 1,
      ...>   event_type: :context_call
      ...> })
      :ok
  """
  @spec record_step(map()) :: :ok | {:error, term()}
  def record_step(attrs)

  @doc """
  Finishes the current trace.

  ## Examples

      iex> finish_trace(:ok)
      :ok

      iex> finish_trace(:error, %{class: "ArgumentError", message: "..."})
      :ok
  """
  @spec finish_trace(atom(), map() | nil) :: :ok | {:error, term()}
  def finish_trace(status, error_info \\ nil)

  @doc """
  Gets the current trace ID from process dictionary.
  """
  @spec current_trace_id() :: binary() | nil
  def current_trace_id()

  @doc """
  Wraps a function with automatic tracing.

  ## Examples

      iex> trace_function("DemoShop.Accounts", "create_user", 1, fn ->
      ...>   # ... function body
      ...> end)
      result
  """
  @spec trace_function(String.t(), String.t(), integer(), function()) :: any()
  def trace_function(module, function, arity, fun)
end
```

---

## Summary

All context modules follow Phoenix conventions:

- **Public API only** - Implementation details are private
- **Proper specs** with `@spec` annotations
- **Documentation** with `@doc` and examples
- **Consistent naming** - `list_*`, `get_*!`, `create_*`, `update_*`, `delete_*`
- **Changesets** for tracking changes in LiveView forms
- **Query optimization** - Preloading associations where needed
- **Error handling** - `{:ok, result}` or `{:error, changeset/reason}` patterns
