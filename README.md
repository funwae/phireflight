# PhireFlight

**A Flight Recorder for Phoenix Contexts**

[![Elixir](https://img.shields.io/badge/Elixir-1.14+-purple.svg)](https://elixir-lang.org/)
[![Phoenix](https://img.shields.io/badge/Phoenix-1.7+-red.svg)](https://www.phoenixframework.org/)
[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

PhireFlight is a runtime instrumentation and visualization tool for Phoenix applications. It records every request as a "flight" through your application's contexts, providing visual diagrams, detailed timelines, and AI-powered analysis of your application's actual runtime behavior.

## Overview

PhireFlight connects your tests and logs to the architecture you *thought* you had. It records every request as a "flight" through your Phoenix contexts, visualizing the actual runtime flow and letting an AI explain what happened.

### The "Flight Recorder" Metaphor

Just like a flight recorder captures every detail of an aircraft's journey, PhireFlight captures every detail of a request's journey through your Phoenix application. You can replay any flight to see exactly how it flowed through your contexts, identify bottlenecks, and catch architectural violations.

## Key Features

- **🛫 Flight Recording**: Every HTTP request becomes a visual "flight" you can replay
- **🗺️ Context Flow Diagrams**: Interactive diagrams showing which contexts participated and in what order
- **⏱️ Flight Timeline**: Step-by-step view of function calls with precise timing (T+0ms format)
- **🤖 AI Narration**: LLM-generated explanations of what happened, why, and potential issues
- **🔍 Pattern Detection**: Identify when code violates context boundaries or shows architectural smells
- **⚡ Real-time Exploration**: LiveView-based UI for interactive flight replay and analysis
- **📊 Application Dashboard**: Overview of all registered apps, contexts, and flight statistics

## Quick Start

### Prerequisites

- **Elixir** 1.14+ (1.15+ recommended for full compatibility)
- **Erlang/OTP** 25+
- **PostgreSQL** 14+
- **Node.js** 18+ (for asset compilation)
- **System packages** (Ubuntu/Debian):
  ```bash
  sudo apt-get install -y build-essential erlang-dev erlang-parsetools
  ```

### Installation

1. **Clone the repository:**
   ```bash
   git clone https://github.com/funwae/phireflight.git
   cd phireflight
   ```

2. **Install dependencies:**
   ```bash
   mix local.hex --force
   mix local.rebar --force
   mix deps.get
   cd assets && npm install && cd ..
   ```

3. **Set up the database:**
   ```bash
   # Create PostgreSQL databases
   createdb phireflight_dev
   createdb phireflight_test

   # Or configure in config/dev.exs and config/test.exs
   mix ecto.setup
   ```

4. **Seed the database:**
   ```bash
   mix run priv/repo/seeds.exs
   ```

5. **Start the server:**
   ```bash
   mix phx.server
   ```

6. **Visit the application:**
   - Main app: [`http://localhost:4000`](http://localhost:4000)
   - Apps dashboard: [`http://localhost:4000/apps`](http://localhost:4000/apps)
   - DemoShop: [`http://localhost:4000/demo/products`](http://localhost:4000/demo/products)

## Demo Application

PhireFlight includes **DemoShop**, a complete e-commerce demo application that showcases PhireFlight's capabilities:

### Quick Demo Flow

1. **Start the server** (see Installation above)
2. **Run seeds**: `mix run priv/repo/seeds.exs`
3. **Try Demo Mode**: Visit `http://localhost:4000/demo/guide` for a guided tour
4. **Or explore manually**:
   - Visit `http://localhost:4000/demo/products` to browse DemoShop
   - Add items to cart and complete a checkout
   - View the flight in PhireFlight at `http://localhost:4000/apps`

### DemoShop Architecture

DemoShop demonstrates proper Phoenix context boundaries with 5 contexts:
- **Accounts**: User management
- **Catalog**: Product and cart management
- **Checkout**: Order processing (includes both "good" and "bad" flow examples)
- **Orders**: Order lifecycle management
- **Billing**: Payment processing

See `docs/10-demo-script-and-demo-mode.md` for a complete walkthrough of the demo flow.

## Configuration

### Database

Configure your database in `config/dev.exs` or set the `DATABASE_URL` environment variable.

Default configuration:
```elixir
config :phireflight, PhireFlight.Repo,
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  database: "phireflight_dev"
```

### LLM Provider

PhireFlight supports multiple LLM providers for AI narration:

- **Claude** (Anthropic): Set `CLAUDE_API_KEY` environment variable
- **OpenAI**: Set `OPENAI_API_KEY` environment variable
- **Mock**: Used by default in development and test

Configure the provider in `config/config.exs`:
```elixir
config :phireflight, :llm_client, PhireFlight.LLMClient.Claude
```

### Demo Mode

Enable the guided demo mode by setting in `config/config.exs`:
```elixir
config :phireflight, :demo_mode, true
```

This enables the `/demo/guide` route for a guided tour of PhireFlight's capabilities.

## Instrumentation

### Adding PhireFlight to Your Phoenix App

1. **Add the Plug to your endpoint:**
   ```elixir
   defmodule YourAppWeb.Endpoint do
     use Phoenix.Endpoint, otp_app: :your_app

     # Add this plug
     plug PhireFlight.Instrumentation.Plug, app_slug: "your-app-slug"
   end
   ```

2. **Register your app in PhireFlight:**
   - Navigate to `http://localhost:4000/apps`
   - Create a new app with your slug (e.g., "your-app-slug")

3. **Wrap context functions:**
   ```elixir
   defmodule YourApp.Accounts do
     alias PhireFlight.Instrumentation.Client

     def get_user(id) do
       Client.trace_function("YourApp.Accounts", "get_user", 1, fn ->
         Repo.get(User, id)
       end)
     end
   end
   ```

See `docs/instrumentation-usage.md` for complete instrumentation guide.

## Testing

Run the test suite:
```bash
mix test
```

The test suite includes:
- **DemoShop context tests**: Accounts, Catalog, Checkout, Orders, Billing
- **DemoShop controller tests**: Product listing, checkout flows
- **PhireFlight core tests**: Traces, TraceEvents, Narrations
- **LiveView UI tests**: Apps, Contexts, Flights

See `docs/08-testing-plan.md` for the complete testing strategy including manual test checklist.

## Development

### Code Formatting

```bash
mix format
```

### Running Tests

```bash
# Run all tests
mix test

# Run tests for a specific module
mix test test/phireflight/traces_test.exs

# Run tests with coverage
mix test --cover
```

### Database Management

```bash
# Create database
mix ecto.create

# Run migrations
mix ecto.migrate

# Rollback last migration
mix ecto.rollback

# Reset database (drop, create, migrate, seed)
mix ecto.reset
```

## Architecture

### Core Concepts

- **Apps**: Registered applications that are being traced
- **Contexts**: Bounded contexts within an application (e.g., Accounts, Billing, Orders)
- **Flights (Traces)**: A single execution flow through multiple contexts
- **Flight Steps (Events)**: Individual operations within a flight
- **Visualizations**: Auto-generated or custom diagram layouts
- **Narrations**: AI-generated analysis of flight patterns

### Technology Stack

- **Backend**: Elixir + Phoenix Framework
- **Frontend**: Phoenix LiveView + Tailwind CSS
- **Database**: PostgreSQL with Ecto
- **AI**: Claude API (Anthropic) or OpenAI (configurable)
- **Visualization**: Custom SVG-based context flow diagrams

### Project Structure

```
phireflight/
├── lib/
│   ├── phireflight/          # Core business logic
│   │   ├── accounts/         # User management
│   │   ├── apps/             # App registration
│   │   ├── contexts/         # Context management
│   │   ├── traces/          # Flight management
│   │   ├── trace_events/      # Event recording
│   │   ├── narrations/       # AI narration
│   │   └── instrumentation/  # Tracing client library
│   ├── phireflight_web/      # Web interface
│   │   ├── live/             # LiveView pages
│   │   └── components/       # Reusable components
│   └── demo_shop/            # Demo application
├── test/                      # Test suite
├── docs/                      # Documentation
└── priv/repo/                  # Migrations and seeds
```

## Project Status

### ✅ Completed Phases

- **Phase 0-1**: Project bootstrap and core data models
- **Phase 2**: Context APIs for all business logic
- **Phase 3**: Basic LiveView UI for apps, contexts, and flights
- **Phase 4**: Instrumentation client library
- **Phase 5**: DemoShop demo application with 5 contexts
- **Demo Polish**: Comprehensive UI redesign, testing infrastructure, and demo mode

### 🚧 Next Steps

See `docs/design/00-implementation-roadmap.md` for the complete implementation plan.

**Phase 6**: Flight Replay Visualization - Enhanced interactive diagrams with animations
**Phase 7**: AI Narration System - Full LLM integration for trace analysis
**Phase 8**: Production Polish - Performance, security, and deployment

## Documentation

Comprehensive documentation is available in the `docs/` directory:

### Design Documents
- [Implementation Roadmap](docs/design/00-implementation-roadmap.md) - Complete implementation plan
- [Project Structure](docs/design/01-project-structure.md) - Folder and module layout
- [Schemas and Types](docs/design/02-schemas-and-types.md) - Database schema design
- [Context APIs](docs/design/03-context-apis.md) - Business logic APIs
- [LiveView Design](docs/design/04-liveview-design.md) - UI components and pages
- [Instrumentation Client](docs/design/05-instrumentation-client.md) - Tracing library
- [AI Narration](docs/design/06-ai-narration.md) - LLM integration
- [DemoShop Example](docs/design/07-demoshop-example-app.md) - Demo application

### User Guides
- [Testing Plan](docs/08-testing-plan.md) - Manual and automated testing strategy
- [UI Branding and Layout](docs/09-ui-branding-and-layout.md) - Visual design system
- [Demo Script and Demo Mode](docs/10-demo-script-and-demo-mode.md) - Demo walkthrough
- [Instrumentation Usage](docs/instrumentation-usage.md) - How to instrument your app
- [Setup Requirements](docs/SETUP-REQUIREMENTS.md) - System dependencies

## Contributing

This project follows Phoenix framework conventions and Elixir style guide.

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

### Code Style

- Follow the [Elixir Style Guide](https://github.com/christopheradams/elixir_style_guide)
- Run `mix format` before committing
- Write tests for new features
- Update documentation as needed

## Troubleshooting

### Compilation Issues

If you encounter compilation errors:
1. Ensure all system dependencies are installed (see Prerequisites)
2. Clean and rebuild: `mix clean && mix deps.clean --all && mix deps.get && mix compile`
3. Check Elixir version: `elixir --version` (should be 1.14+)

### Database Connection Issues

If you see database connection errors:
1. Ensure PostgreSQL is running: `sudo systemctl status postgresql`
2. Verify database credentials in `config/dev.exs`
3. Create databases manually if needed: `createdb phireflight_dev`

### Test Failures

If tests fail:
1. Ensure test database exists: `MIX_ENV=test mix ecto.create`
2. Run migrations: `MIX_ENV=test mix ecto.migrate`
3. Check for missing seeds: `MIX_ENV=test mix run priv/repo/seeds.exs`

## License

Copyright © 2025

This project is licensed under the MIT License - see the LICENSE file for details.

## Acknowledgments

- Built with [Phoenix Framework](https://www.phoenixframework.org/)
- UI powered by [Tailwind CSS](https://tailwindcss.com/)
- Icons from [Heroicons](https://heroicons.com/)
- AI narration powered by [Anthropic Claude](https://www.anthropic.com/) or [OpenAI](https://openai.com/)

---

**Status**: Phase 5 Complete - Ready for Phase 6 (Flight Replay Visualization)

For questions or issues, please open an issue on [GitHub](https://github.com/funwae/phireflight/issues).
