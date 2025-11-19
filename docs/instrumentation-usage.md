# PhireFlight Instrumentation Client - Usage Guide

## Overview

The PhireFlight Instrumentation Client provides a simple way to trace your Phoenix application and send trace data to PhireFlight for visualization and analysis.

## Quick Start

### 1. Add the Plug to Your Endpoint

In your Phoenix application's endpoint file:

```elixir
defmodule YourAppWeb.Endpoint do
  use Phoenix.Endpoint, otp_app: :your_app

  # ... other plugs ...

  # Add this plug to automatically trace all HTTP requests
  plug PhireFlight.Instrumentation.Plug, app_slug: "your-app-slug"

  # ... rest of endpoint ...
end
```

### 2. Register Your App in PhireFlight

Before tracing will work, you need to register your app in PhireFlight:

1. Start PhireFlight: `mix phx.server`
2. Navigate to `http://localhost:4000/apps`
3. Create a new app with a slug (e.g., "your-app-slug")
4. Copy the API key (if using external apps in the future)

### 3. Trace Context Functions

Wrap your context functions with `trace_function/4`:

```elixir
defmodule YourApp.Accounts do
  alias PhireFlight.Instrumentation.Client

  def get_user(id) do
    Client.trace_function("YourApp.Accounts", "get_user", 1, fn ->
      # Your existing code
      Repo.get(User, id)
    end)
  end

  def create_user(attrs) do
    Client.trace_function("YourApp.Accounts", "create_user", 1, fn ->
      %User{}
      |> User.changeset(attrs)
      |> Repo.insert()
    end)
  end
end
```

## Manual Tracing

For more control, you can manually record steps:

```elixir
defmodule YourApp.Checkout do
  alias PhireFlight.Instrumentation.Client

  def process_checkout(cart) do
    # Record that we're entering the checkout process
    Client.record_step(%{
      module: "YourApp.Checkout",
      function: "process_checkout",
      arity: 1,
      event_type: :context_call,
      context_name: "Checkout"
    })

    # Your checkout logic here
    result = do_checkout(cart)

    result
  end
end
```

## Context Auto-Discovery

The client automatically discovers and creates contexts based on module names:

- `YourApp.Accounts.User` → Creates "Accounts" context
- `YourApp.Billing.Payment` → Creates "Billing" context

You can also explicitly provide a `context_name` in `record_step/1`.

## Event Types

The client automatically detects event types from module names:

- Modules ending in `Controller` → `:controller`
- Modules ending in `Live` → `:liveview`
- Modules containing `Repo` → `:db_query`
- Everything else → `:context_call`

## Error Tracking

Errors are automatically captured:

```elixir
# Errors in trace_function are automatically recorded
Client.trace_function("YourApp.Accounts", "get_user", 1, fn ->
  raise "User not found"
end)
# The error is recorded with error: true and error_message
```

## Viewing Traces

1. Navigate to your app in PhireFlight: `http://localhost:4000/apps/your-app-id`
2. Click on "Recent Flights" to see traces
3. Click on a trace to see the detailed flight replay

## Advanced Usage

### Custom Metadata

Include custom metadata in traces:

```elixir
Client.start_trace(%{
  app_slug: "your-app",
  entry_point: "GET /checkout",
  metadata: %{
    user_id: user.id,
    session_id: session.id
  }
})
```

### Include Request Params/Headers

In your endpoint:

```elixir
plug PhireFlight.Instrumentation.Plug,
  app_slug: "your-app",
  include_params: true,
  include_headers: true
```

## Testing

The instrumentation client is designed to be test-friendly. In tests, traces are stored in the database and can be queried:

```elixir
defmodule YourApp.SomeTest do
  use YourApp.DataCase

  test "traces are created" do
    # Your test code that triggers tracing
    # ...

    # Verify trace was created
    traces = PhireFlight.Traces.list_all_traces()
    assert length(traces) > 0
  end
end
```

## Best Practices

1. **Trace at Context Boundaries**: Focus on tracing calls between contexts, not every function
2. **Use Meaningful Names**: Use clear module and function names for better visualization
3. **Don't Trace Internal Functions**: Only trace public API functions
4. **Handle Errors Gracefully**: The client handles errors, but ensure your app continues to work

## Troubleshooting

### Traces Not Appearing

1. Check that your app is registered in PhireFlight
2. Verify the `app_slug` matches exactly
3. Check logs for error messages
4. Ensure the database is set up and migrations are run

### Performance Concerns

- Tracing is lightweight but adds some overhead
- Consider disabling in high-throughput scenarios
- Use async tracing for external apps (future feature)

## Next Steps

- See Phase 5 documentation for building the DemoShop example app
- Check the design docs for advanced features coming in future phases

