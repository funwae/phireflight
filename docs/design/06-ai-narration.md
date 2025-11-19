# PhireFlight AI Narration System

## Overview
This document defines the AI narration system that generates explanations and architectural analysis for traces using LLMs.

---

## Architecture

### Component Overview

```
┌─────────────────────────────────────────────────────┐
│                  Narrations Context                  │
│  ┌───────────────────────────────────────────────┐  │
│  │            Generator                           │  │
│  │  • Builds prompts                             │  │
│  │  • Calls LLM Client                           │  │
│  │  • Parses responses                           │  │
│  │  • Persists narrations                        │  │
│  └───────────────────────────────────────────────┘  │
│  ┌───────────────────────────────────────────────┐  │
│  │         PromptBuilder                         │  │
│  │  • Formats trace data                         │  │
│  │  • Adds context descriptions                  │  │
│  │  • Structures LLM prompts                     │  │
│  └───────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────┘
                          │
                          ▼
         ┌────────────────────────────────┐
         │       LLM Client Behaviour      │
         └────────────────────────────────┘
                          │
         ┌────────────────┴────────────────┐
         ▼                                  ▼
  ┌─────────────┐                  ┌─────────────┐
  │   Claude    │                  │   OpenAI    │
  │Implementation│                  │Implementation│
  └─────────────┘                  └─────────────┘
```

---

## Module: PhireFlight.Narrations.Generator

**File:** `lib/phireflight/narrations/generator.ex`

### Implementation

```elixir
defmodule PhireFlight.Narrations.Generator do
  @moduledoc """
  Generates AI narrations for traces.
  """

  alias PhireFlight.{Traces, TraceEvents, Narrations, Apps, Contexts}
  alias PhireFlight.Narrations.{Narration, PromptBuilder}
  alias PhireFlight.LLMClient
  alias PhireFlight.Repo
  require Logger

  @default_model "claude-3-5-sonnet-20241022"

  @doc """
  Generates a narration for a trace.

  ## Options

    * `:model` - LLM model to use (default: from config or #{@default_model})
    * `:regenerate` - Force regeneration even if exists (default: false)
    * `:temperature` - LLM temperature (default: 0.2 for consistent output)

  ## Returns

    * `{:ok, narration}` - Successfully generated
    * `{:error, :already_exists}` - Narration exists and regenerate not set
    * `{:error, reason}` - Generation failed
  """
  @spec generate(binary(), keyword()) :: {:ok, Narration.t()} | {:error, term()}
  def generate(trace_id, opts \\ []) do
    with {:ok, _} <- check_existing(trace_id, opts[:regenerate]),
         {:ok, trace} <- load_trace(trace_id),
         {:ok, prompt_data} <- build_prompt_data(trace),
         {:ok, llm_response} <- call_llm(prompt_data, opts),
         {:ok, narration} <- persist_narration(trace_id, llm_response, opts) do
      {:ok, narration}
    end
  end

  ## Private Functions

  defp check_existing(trace_id, true = _regenerate) do
    # Delete existing narration if regenerating
    case Narrations.get_narration_by_trace_id(trace_id) do
      nil -> {:ok, :no_existing}
      narration ->
        Narrations.delete_narration(narration)
        {:ok, :deleted_existing}
    end
  end

  defp check_existing(trace_id, _regenerate) do
    case Narrations.get_narration_by_trace_id(trace_id) do
      nil -> {:ok, :no_existing}
      _narration -> {:error, :already_exists}
    end
  end

  defp load_trace(trace_id) do
    trace =
      trace_id
      |> Traces.get_trace!()
      |> Repo.preload([:app, trace_events: [:app_context]])

    {:ok, trace}
  rescue
    Ecto.NoResultsError -> {:error, :trace_not_found}
  end

  defp build_prompt_data(trace) do
    app = trace.app
    contexts = Contexts.list_app_contexts(app.id)
    events = trace.trace_events

    prompt_data = %{
      app: %{
        name: app.name,
        description: app.description
      },
      contexts: build_contexts_summary(contexts),
      trace: %{
        id: trace.id,
        entry_point: trace.entry_point,
        status: trace.status,
        duration_ms: trace.duration_ms,
        error_class: trace.error_class,
        error_message: trace.error_message
      },
      events: build_events_summary(events)
    }

    {:ok, prompt_data}
  end

  defp build_contexts_summary(contexts) do
    Enum.map(contexts, fn context ->
      %{
        name: context.name,
        full_name: context.full_name,
        description: context.description,
        kind: context.kind
      }
    end)
  end

  defp build_events_summary(events) do
    Enum.map(events, fn event ->
      %{
        sequence: event.sequence_index,
        module: event.module,
        function: event.function,
        arity: event.arity,
        event_type: event.event_type,
        context: event.app_context && event.app_context.name,
        duration_ms: event.duration_ms,
        error: event.error,
        error_message: event.error_message
      }
    end)
  end

  defp call_llm(prompt_data, opts) do
    started_at = System.monotonic_time(:millisecond)

    model = opts[:model] || get_default_model()
    temperature = opts[:temperature] || 0.2

    messages = PromptBuilder.build_messages(prompt_data)

    case LLMClient.complete(messages, model: model, temperature: temperature) do
      {:ok, response} ->
        generation_time_ms = System.monotonic_time(:millisecond) - started_at

        parsed = parse_llm_response(response.content)

        {:ok,
         Map.merge(parsed, %{
           model_name: response.model,
           generation_time_ms: generation_time_ms
         })}

      {:error, reason} ->
        Logger.error("LLM call failed: #{inspect(reason)}")
        {:error, reason}
    end
  end

  defp parse_llm_response(content) do
    # Try to parse as JSON first
    case Jason.decode(content) do
      {:ok, %{"summary" => summary} = json} ->
        %{
          summary: summary,
          details: json["details"],
          issues: json["issues"] || []
        }

      _ ->
        # Fallback: treat entire response as summary
        %{
          summary: String.slice(content, 0, 1000),
          details: nil,
          issues: []
        }
    end
  end

  defp persist_narration(trace_id, llm_data, _opts) do
    attrs = %{
      trace_id: trace_id,
      model_name: llm_data.model_name,
      summary: llm_data.summary,
      details: llm_data.details,
      issues: llm_data.issues,
      generation_time_ms: llm_data.generation_time_ms
    }

    Narrations.create_narration(attrs)
  end

  defp get_default_model do
    Application.get_env(:phireflight, :default_llm_model, @default_model)
  end
end
```

---

## Module: PhireFlight.Narrations.PromptBuilder

**File:** `lib/phireflight/narrations/prompt_builder.ex`

### Implementation

```elixir
defmodule PhireFlight.Narrations.PromptBuilder do
  @moduledoc """
  Builds prompts for LLM narration generation.
  """

  @system_prompt """
  You are an expert Elixir/Phoenix architecture analyst. You will receive a trace of a single request through a Phoenix application, showing the sequence of context function calls.

  Your task is to:

  1. **Summarize** what happened in this trace in 2-4 sentences.
  2. **Identify architectural issues** such as:
     - Cross-context calls that bypass public APIs
     - Controllers or LiveViews calling Repo directly
     - Circular context dependencies
     - Excessive context coupling
     - Missing validations or boundary checks
  3. **Return your analysis as JSON** with this structure:

  {
    "summary": "A 2-4 sentence summary of what this trace did",
    "details": "Optional longer explanation if needed",
    "issues": [
      {
        "type": "issue_type_identifier",
        "severity": "info|warn|error",
        "description": "Human-readable description of the issue"
      }
    ]
  }

  Be constructive and specific. Focus on architectural patterns, not code style.
  """

  @doc """
  Builds messages for LLM completion.

  Returns a list of message maps with :role and :content.
  """
  @spec build_messages(map()) :: [map()]
  def build_messages(prompt_data) do
    [
      %{
        role: "system",
        content: @system_prompt
      },
      %{
        role: "user",
        content: build_user_message(prompt_data)
      }
    ]
  end

  defp build_user_message(data) do
    """
    ## Application

    **Name:** #{data.app.name}
    #{if data.app.description, do: "**Description:** #{data.app.description}\n", else: ""}

    ## Contexts

    #{build_contexts_section(data.contexts)}

    ## Trace

    **Entry Point:** #{data.trace.entry_point}
    **Status:** #{data.trace.status}
    **Duration:** #{data.trace.duration_ms}ms
    #{if data.trace.error_class, do: "**Error:** #{data.trace.error_class} - #{data.trace.error_message}\n", else: ""}

    ## Event Sequence

    #{build_events_section(data.events)}

    ---

    Please analyze this trace and return your findings as JSON.
    """
  end

  defp build_contexts_section(contexts) do
    contexts
    |> Enum.map(fn context ->
      """
      ### #{context.name} (#{context.kind})
      #{if context.description, do: context.description, else: "No description"}
      """
    end)
    |> Enum.join("\n")
  end

  defp build_events_section(events) do
    events
    |> Enum.map(fn event ->
      error_indicator = if event.error, do: " ⚠️ ERROR", else: ""
      context_name = event.context || "unknown"

      """
      #{event.sequence}. **[#{context_name}]** `#{event.module}.#{event.function}/#{event.arity}` (#{event.event_type}, #{event.duration_ms}ms)#{error_indicator}
      #{if event.error_message, do: "   Error: #{event.error_message}", else: ""}
      """
    end)
    |> Enum.join("\n")
  end
end
```

---

## Module: PhireFlight.LLMClient.Behaviour

**File:** `lib/phireflight/llm_client/behaviour.ex`

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

---

## Module: PhireFlight.LLMClient.Claude

**File:** `lib/phireflight/llm_client/claude.ex`

### Implementation

```elixir
defmodule PhireFlight.LLMClient.Claude do
  @moduledoc """
  Claude AI provider implementation using the Anthropic API.
  """

  @behaviour PhireFlight.LLMClient.Behaviour

  @api_url "https://api.anthropic.com/v1/messages"
  @api_version "2023-06-01"

  @impl true
  def complete(messages, opts \\ []) do
    model = opts[:model] || "claude-3-5-sonnet-20241022"
    temperature = opts[:temperature] || 0.2
    max_tokens = opts[:max_tokens] || 4096

    request_body = %{
      model: model,
      messages: convert_messages(messages),
      temperature: temperature,
      max_tokens: max_tokens,
      system: extract_system_message(messages)
    }

    headers = [
      {"Content-Type", "application/json"},
      {"x-api-key", get_api_key()},
      {"anthropic-version", @api_version}
    ]

    case Req.post(@api_url, json: request_body, headers: headers) do
      {:ok, %{status: 200, body: body}} ->
        parse_claude_response(body)

      {:ok, %{status: status, body: body}} ->
        {:error, "API error #{status}: #{inspect(body)}"}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp convert_messages(messages) do
    messages
    |> Enum.reject(&(&1.role == "system"))
    |> Enum.map(fn msg ->
      %{
        role: msg.role,
        content: msg.content
      }
    end)
  end

  defp extract_system_message(messages) do
    case Enum.find(messages, &(&1.role == "system")) do
      nil -> nil
      msg -> msg.content
    end
  end

  defp parse_claude_response(body) do
    content =
      body["content"]
      |> List.first()
      |> Map.get("text")

    {:ok,
     %{
       content: content,
       model: body["model"],
       usage: %{
         input_tokens: get_in(body, ["usage", "input_tokens"]) || 0,
         output_tokens: get_in(body, ["usage", "output_tokens"]) || 0
       }
     }}
  end

  defp get_api_key do
    Application.get_env(:phireflight, :anthropic_api_key) ||
      System.get_env("ANTHROPIC_API_KEY") ||
      raise "ANTHROPIC_API_KEY not configured"
  end
end
```

---

## Module: PhireFlight.LLMClient.OpenAI

**File:** `lib/phireflight/llm_client/openai.ex`

### Implementation

```elixir
defmodule PhireFlight.LLMClient.OpenAI do
  @moduledoc """
  OpenAI provider implementation.
  """

  @behaviour PhireFlight.LLMClient.Behaviour

  @api_url "https://api.openai.com/v1/chat/completions"

  @impl true
  def complete(messages, opts \\ []) do
    model = opts[:model] || "gpt-4o"
    temperature = opts[:temperature] || 0.2
    max_tokens = opts[:max_tokens] || 4096

    request_body = %{
      model: model,
      messages: convert_messages(messages),
      temperature: temperature,
      max_tokens: max_tokens
    }

    headers = [
      {"Content-Type", "application/json"},
      {"Authorization", "Bearer #{get_api_key()}"}
    ]

    case Req.post(@api_url, json: request_body, headers: headers) do
      {:ok, %{status: 200, body: body}} ->
        parse_openai_response(body)

      {:ok, %{status: status, body: body}} ->
        {:error, "API error #{status}: #{inspect(body)}"}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp convert_messages(messages) do
    Enum.map(messages, fn msg ->
      %{
        role: msg.role,
        content: msg.content
      }
    end)
  end

  defp parse_openai_response(body) do
    choice = List.first(body["choices"])
    content = get_in(choice, ["message", "content"])

    {:ok,
     %{
       content: content,
       model: body["model"],
       usage: %{
         input_tokens: get_in(body, ["usage", "prompt_tokens"]) || 0,
         output_tokens: get_in(body, ["usage", "completion_tokens"]) || 0
       }
     }}
  end

  defp get_api_key do
    Application.get_env(:phireflight, :openai_api_key) ||
      System.get_env("OPENAI_API_KEY") ||
      raise "OPENAI_API_KEY not configured"
  end
end
```

---

## Module: PhireFlight.LLMClient.Mock

**File:** `lib/phireflight/llm_client/mock.ex`

### Implementation (for testing)

```elixir
defmodule PhireFlight.LLMClient.Mock do
  @moduledoc """
  Mock LLM client for testing.
  """

  @behaviour PhireFlight.LLMClient.Behaviour

  @impl true
  def complete(_messages, _opts \\ []) do
    # Return a canned response
    {:ok,
     %{
       content: Jason.encode!(%{
         summary: "This is a mock trace narration for testing purposes.",
         details: "The trace executed successfully with no issues detected.",
         issues: []
       }),
       model: "mock-model",
       usage: %{
         input_tokens: 100,
         output_tokens: 50
       }
     }}
  end
end
```

---

## Module: PhireFlight.LLMClient (Main)

**File:** `lib/phireflight/llm_client/llm_client.ex`

### Implementation

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

## Configuration

### config/config.exs

```elixir
config :phireflight,
  llm_provider: PhireFlight.LLMClient.Mock,  # Use mock by default
  default_llm_model: "claude-3-5-sonnet-20241022"
```

### config/dev.exs

```elixir
# Use real Claude in dev if API key is set
if System.get_env("ANTHROPIC_API_KEY") do
  config :phireflight,
    llm_provider: PhireFlight.LLMClient.Claude
end
```

### config/prod.exs

```elixir
config :phireflight,
  llm_provider: PhireFlight.LLMClient.Claude

# API keys should be set via runtime.exs or environment variables
```

### config/runtime.exs

```elixir
if config_env() == :prod do
  config :phireflight,
    anthropic_api_key: System.get_env("ANTHROPIC_API_KEY"),
    openai_api_key: System.get_env("OPENAI_API_KEY")
end
```

---

## Example Issue Types

The AI narration system will detect these architectural issues:

### Cross-Context Leak
```json
{
  "type": "cross_context_leak",
  "severity": "warn",
  "description": "Billing context called Accounts.User schema directly instead of using Accounts public API"
}
```

### Direct Repo Access
```json
{
  "type": "direct_repo_access",
  "severity": "error",
  "description": "CheckoutController called Repo.insert/1 directly. Database access should be encapsulated in context functions"
}
```

### Circular Dependency
```json
{
  "type": "circular_dependency",
  "severity": "error",
  "description": "Detected circular call: Accounts → Billing → Accounts. This indicates a design issue"
}
```

### Missing Validation
```json
{
  "type": "missing_validation",
  "severity": "info",
  "description": "No validation step detected before database insert. Consider adding changeset validation"
}
```

### N+1 Query Pattern
```json
{
  "type": "n_plus_one_query",
  "severity": "warn",
  "description": "Multiple sequential database queries detected. Consider using preloads or batch loading"
}
```

---

## Testing Strategy

### Unit Tests

**File:** `test/phireflight/narrations/generator_test.exs`

```elixir
defmodule PhireFlight.Narrations.GeneratorTest do
  use PhireFlight.DataCase

  alias PhireFlight.Narrations.Generator
  alias PhireFlight.{Apps, Contexts, Traces, TraceEvents}

  setup do
    # Create test app with contexts and trace
    {:ok, app} = Apps.create_app(%{
      name: "Test App",
      slug: "test-app",
      owner_id: insert(:user).id
    })

    {:ok, context} = Contexts.create_app_context(%{
      app_id: app.id,
      name: "Accounts",
      description: "User management"
    })

    {:ok, trace} = Traces.start_trace(%{
      app_id: app.id,
      entry_point: "GET /users",
      started_at: DateTime.utc_now()
    })

    {:ok, _event} = TraceEvents.record_event(%{
      trace_id: trace.id,
      app_context_id: context.id,
      module: "TestApp.Accounts",
      function: "list_users",
      arity: 0,
      event_type: :context_call,
      sequence_index: 0,
      started_at: DateTime.utc_now()
    })

    Traces.finish_trace(trace, %{
      status: :ok,
      finished_at: DateTime.utc_now()
    })

    %{trace: trace}
  end

  test "generates narration for a trace", %{trace: trace} do
    {:ok, narration} = Generator.generate(trace.id)

    assert narration.summary
    assert narration.model_name
    assert narration.generation_time_ms
  end

  test "returns error if narration already exists", %{trace: trace} do
    {:ok, _} = Generator.generate(trace.id)
    assert {:error, :already_exists} = Generator.generate(trace.id)
  end

  test "regenerates if regenerate option is true", %{trace: trace} do
    {:ok, narration1} = Generator.generate(trace.id)
    {:ok, narration2} = Generator.generate(trace.id, regenerate: true)

    assert narration1.id != narration2.id
  end
end
```

---

## Summary

**AI Narration Features:**

- ✅ **Structured prompts** - Clear system instructions and formatted trace data
- ✅ **Multiple providers** - Claude, OpenAI, Mock (for testing)
- ✅ **Architectural analysis** - Detects common Phoenix context anti-patterns
- ✅ **JSON responses** - Structured output for easy parsing
- ✅ **Issue categorization** - Type, severity, description
- ✅ **Async generation** - Can be triggered from LiveView without blocking
- ✅ **Configurable models** - Support different LLM models
- ✅ **Usage tracking** - Records generation time and token usage
- 🔮 **Future: Caching** - Cache narrations for identical traces
- 🔮 **Future: Batch generation** - Generate for multiple traces at once
- 🔮 **Future: Custom rules** - User-defined architectural rules

**Prompt Engineering:**
- System prompt sets expert role and JSON format
- Context descriptions provide domain knowledge
- Event sequence shows actual execution flow
- Asks for specific issue types we care about
