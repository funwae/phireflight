# PhireFlight Project Structure

## Overview
This document defines the complete folder and module structure for the PhireFlight Phoenix/LiveView application.

## Root Structure

```
phireflight/
├── config/
│   ├── config.exs
│   ├── dev.exs
│   ├── prod.exs
│   ├── runtime.exs
│   └── test.exs
├── lib/
│   ├── phireflight/
│   │   ├── accounts/
│   │   ├── apps/
│   │   ├── contexts/
│   │   ├── traces/
│   │   ├── trace_events/
│   │   ├── visualizations/
│   │   ├── narrations/
│   │   ├── llm_client/
│   │   ├── instrumentation/
│   │   ├── application.ex
│   │   ├── repo.ex
│   │   └── mailer.ex
│   ├── phireflight_web/
│   │   ├── components/
│   │   ├── controllers/
│   │   ├── live/
│   │   ├── endpoint.ex
│   │   ├── gettext.ex
│   │   ├── router.ex
│   │   └── telemetry.ex
│   ├── demo_shop/
│   │   ├── accounts/
│   │   ├── catalog/
│   │   ├── checkout/
│   │   ├── orders/
│   │   ├── billing/
│   │   ├── application.ex
│   │   └── repo.ex
│   ├── demo_shop_web/
│   │   ├── controllers/
│   │   ├── live/
│   │   ├── endpoint.ex
│   │   ├── router.ex
│   │   └── telemetry.ex
│   ├── phireflight.ex
│   └── phireflight_web.ex
├── priv/
│   ├── repo/
│   │   ├── migrations/
│   │   └── seeds.exs
│   ├── static/
│   └── gettext/
├── test/
│   ├── phireflight/
│   ├── phireflight_web/
│   ├── demo_shop/
│   ├── support/
│   └── test_helper.exs
├── assets/
│   ├── js/
│   │   ├── app.js
│   │   └── hooks/
│   │       ├── trace_diagram.js
│   │       └── timeline_player.js
│   ├── css/
│   │   └── app.css
│   └── tailwind.config.js
├── docs/
│   ├── design/
│   └── architecture/
├── mix.exs
├── mix.lock
└── README.md
```

## Core PhireFlight Contexts

### 1. Accounts Context
**Location:** `lib/phireflight/accounts/`

```
accounts/
├── user.ex                    # Schema
├── user_token.ex              # Schema
├── user_notifier.ex           # Email notifications
└── accounts.ex                # Public API (moved up)
```

**Main Module:** `PhireFlight.Accounts`

### 2. Apps Context
**Location:** `lib/phireflight/apps/`

```
apps/
├── app.ex                     # Schema
└── apps.ex                    # Public API (moved up)
```

**Main Module:** `PhireFlight.Apps`

### 3. Contexts Context
**Location:** `lib/phireflight/contexts/`

```
contexts/
├── app_context.ex             # Schema
├── context_kind.ex            # Ecto enum
└── contexts.ex                # Public API (moved up)
```

**Main Module:** `PhireFlight.Contexts`

### 4. Traces Context
**Location:** `lib/phireflight/traces/`

```
traces/
├── trace.ex                   # Schema
├── trace_status.ex            # Ecto enum
├── queries.ex                 # Specialized queries
└── traces.ex                  # Public API (moved up)
```

**Main Module:** `PhireFlight.Traces`

### 5. TraceEvents Context
**Location:** `lib/phireflight/trace_events/`

```
trace_events/
├── trace_event.ex             # Schema
├── event_type.ex              # Ecto enum
├── analyzer.ex                # Analyze patterns
└── trace_events.ex            # Public API (moved up)
```

**Main Module:** `PhireFlight.TraceEvents`

### 6. Visualizations Context
**Location:** `lib/phireflight/visualizations/`

```
visualizations/
├── visualization_layout.ex    # Schema
├── layout_calculator.ex       # Auto-layout algorithms
└── visualizations.ex          # Public API (moved up)
```

**Main Module:** `PhireFlight.Visualizations`

### 7. Narrations Context
**Location:** `lib/phireflight/narrations/`

```
narrations/
├── narration.ex               # Schema
├── generator.ex               # Generate from traces
├── prompt_builder.ex          # Build LLM prompts
└── narrations.ex              # Public API (moved up)
```

**Main Module:** `PhireFlight.Narrations`

### 8. LLM Client (Infrastructure)
**Location:** `lib/phireflight/llm_client/`

```
llm_client/
├── behaviour.ex               # Behaviour definition
├── claude.ex                  # Claude implementation
├── openai.ex                  # OpenAI implementation
└── mock.ex                    # Testing implementation
```

**Main Module:** `PhireFlight.LLMClient`

### 9. Instrumentation (Client Library)
**Location:** `lib/phireflight/instrumentation/`

```
instrumentation/
├── client.ex                  # Main client API
├── storage.ex                 # Process dictionary storage
├── http_reporter.ex           # HTTP event reporter
└── plug.ex                    # Plug for Phoenix apps
```

**Main Module:** `PhireFlight.Instrumentation`

## PhireFlight Web (LiveView UI)

**Location:** `lib/phireflight_web/`

### Components
```
components/
├── core_components.ex         # Phoenix default components
├── layouts/
│   ├── root.html.heex
│   └── app.html.heex
├── trace_diagram.ex           # Context diagram component
├── trace_timeline.ex          # Event timeline component
├── narration_panel.ex         # AI narration display
└── context_card.ex            # Context info card
```

### LiveViews
```
live/
├── apps_live/
│   ├── index.ex               # List all apps
│   ├── show.ex                # App detail + contexts
│   └── form_component.ex      # Create/edit app
├── contexts_live/
│   ├── index.ex               # Manage contexts
│   └── form_component.ex      # Create/edit context
├── traces_live/
│   ├── index.ex               # List all traces
│   └── show.ex                # Flight replay view ⭐
└── layouts_live/
    ├── index.ex               # Manage visualization layouts
    └── form_component.ex      # Edit layout
```

### Controllers (API)
```
controllers/
├── api/
│   ├── trace_controller.ex    # Ingest traces
│   └── event_controller.ex    # Ingest events
└── page_controller.ex         # Landing page
```

## DemoShop (Demo Application)

**Location:** `lib/demo_shop/`

### DemoShop Contexts
```
demo_shop/
├── accounts/
│   ├── user.ex
│   └── accounts.ex
├── catalog/
│   ├── product.ex
│   ├── cart.ex
│   ├── cart_item.ex
│   └── catalog.ex
├── checkout/
│   ├── checkout_session.ex
│   └── checkout.ex
├── orders/
│   ├── order.ex
│   ├── order_line_item.ex
│   └── orders.ex
├── billing/
│   ├── payment.ex
│   ├── charge.ex
│   └── billing.ex
├── application.ex
└── repo.ex
```

### DemoShop Web
**Location:** `lib/demo_shop_web/`

```
demo_shop_web/
├── controllers/
│   ├── page_controller.ex
│   ├── product_controller.ex
│   ├── cart_controller.ex
│   └── checkout_controller.ex
├── live/
│   ├── product_live/
│   │   └── index.ex
│   └── checkout_live/
│       └── show.ex
├── endpoint.ex
├── router.ex
└── telemetry.ex
```

## Database Migrations

**Location:** `priv/repo/migrations/`

Migrations will be numbered sequentially:
1. `YYYYMMDDHHMMSS_create_users.exs`
2. `YYYYMMDDHHMMSS_create_apps.exs`
3. `YYYYMMDDHHMMSS_create_app_contexts.exs`
4. `YYYYMMDDHHMMSS_create_traces.exs`
5. `YYYYMMDDHHMMSS_create_trace_events.exs`
6. `YYYYMMDDHHMMSS_create_visualization_layouts.exs`
7. `YYYYMMDDHHMMSS_create_narrations.exs`
8. `YYYYMMDDHHMMSS_create_demo_shop_tables.exs`

## Assets & Frontend

### JavaScript Hooks
**Location:** `assets/js/hooks/`

- `trace_diagram.js` - Interactive SVG diagram with D3.js or similar
- `timeline_player.js` - Animated playback of trace events

### CSS
**Location:** `assets/css/`

- `app.css` - Main Tailwind CSS entry point
- Custom components for diagram nodes/edges

## Testing Structure

```
test/
├── phireflight/
│   ├── accounts_test.exs
│   ├── apps_test.exs
│   ├── contexts_test.exs
│   ├── traces_test.exs
│   ├── trace_events_test.exs
│   ├── visualizations_test.exs
│   ├── narrations_test.exs
│   └── instrumentation_test.exs
├── phireflight_web/
│   ├── controllers/
│   └── live/
├── demo_shop/
│   ├── accounts_test.exs
│   ├── catalog_test.exs
│   ├── checkout_test.exs
│   ├── orders_test.exs
│   └── billing_test.exs
└── support/
    ├── conn_case.ex
    ├── data_case.ex
    └── fixtures/
        ├── accounts_fixtures.ex
        ├── apps_fixtures.ex
        ├── traces_fixtures.ex
        └── demo_shop_fixtures.ex
```

## Configuration Highlights

### config/config.exs
- Ecto repos configuration
- Endpoint configuration
- LLM client provider selection

### config/runtime.exs
- Database URL from env
- API keys for LLM providers
- Secret key base

### config/dev.exs
- Live reload
- Debug logging
- Dev-specific endpoint settings

### config/test.exs
- Test database
- Mock LLM client
- Async testing settings

## Key Dependencies (mix.exs)

```elixir
defp deps do
  [
    {:phoenix, "~> 1.7.14"},
    {:phoenix_ecto, "~> 4.5"},
    {:ecto_sql, "~> 3.11"},
    {:postgrex, ">= 0.0.0"},
    {:phoenix_html, "~> 4.1"},
    {:phoenix_live_reload, "~> 1.5", only: :dev},
    {:phoenix_live_view, "~> 0.20.17"},
    {:floki, ">= 0.36.0", only: :test},
    {:phoenix_live_dashboard, "~> 0.8"},
    {:esbuild, "~> 0.8", runtime: Mix.env() == :dev},
    {:tailwind, "~> 0.2", runtime: Mix.env() == :dev},
    {:heroicons,
     github: "tailwindlabs/heroicons",
     tag: "v2.1.1",
     sparse: "optimized",
     app: false,
     compile: false,
     depth: 1},
    {:swoosh, "~> 1.16"},
    {:finch, "~> 0.18"},
    {:telemetry_metrics, "~> 1.0"},
    {:telemetry_poller, "~> 1.1"},
    {:gettext, "~> 0.24"},
    {:jason, "~> 1.4"},
    {:dns_cluster, "~> 0.1.3"},
    {:bandit, "~> 1.5"},
    {:req, "~> 0.4.0"},  # For HTTP client (LLM APIs)
    {:uuid, "~> 1.1"}     # For trace IDs
  ]
end
```

## Notes

- **Single Postgres DB**: Both PhireFlight and DemoShop use the same database for MVP simplicity
- **Umbrella Alternative**: Could be converted to umbrella app later if needed
- **Instrumentation**: The instrumentation client lives in PhireFlight repo but is designed to be extracted as a hex package later
- **API Keys**: For MVP, DemoShop can call PhireFlight contexts directly; HTTP API is there for future external apps
