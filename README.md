# PhireFlight

**AI-Powered Application Context Flow Visualization**

PhireFlight is a Phoenix LiveView application that visualizes and analyzes how context boundaries interact across your application using AI-powered insights.

## Features

- **Trace Visualization**: Interactive diagrams showing context boundaries and data flow
- **AI-Powered Narration**: LLM-generated analysis of traces to identify architectural issues
- **Real-time Monitoring**: LiveView-based UI for real-time trace exploration
- **Context Mapping**: Visual representation of bounded contexts and their interactions
- **Pattern Detection**: Automatic identification of anti-patterns and architectural smells

## Project Status

This project has completed **Phase 0** (Project Bootstrap) and **Phase 1** (Core Data Models).

### Completed

- ✅ Phoenix project structure with LiveView
- ✅ Database schemas and migrations for all core entities:
  - Users (authentication ready)
  - Apps
  - AppContexts
  - Traces
  - TraceEvents
  - VisualizationLayouts
  - Narrations
- ✅ Configuration files for all environments
- ✅ Core application infrastructure

### Next Steps

See `docs/design/00-implementation-roadmap.md` for the complete implementation plan.

**Phase 2**: Context APIs - Implement business logic for all contexts
**Phase 3**: Basic LiveView UI - Create functional UI for apps, contexts, and traces
**Phase 4**: Instrumentation Client - Build the tracing client library
**Phase 5**: DemoShop Application - Build demo e-commerce app
**Phase 6**: Flight Replay Visualization - Interactive trace diagrams
**Phase 7**: AI Narration System - LLM integration for trace analysis
**Phase 8**: Polish & Demo Prep - Make it production-ready

## Prerequisites

- Elixir 1.14 or later
- Erlang/OTP 25 or later
- PostgreSQL 14+
- Node.js 18+ (for asset compilation)

## Getting Started

1. Clone the repository:
   ```bash
   git clone https://github.com/funwae/phireflight.git
   cd phireflight
   ```

2. Install dependencies:
   ```bash
   mix local.rebar --force
   mix local.hex --force
   mix deps.get
   cd assets && npm install && cd ..
   ```

3. Create and migrate your database:
   ```bash
   mix ecto.setup
   ```

4. Start the Phoenix server:
   ```bash
   mix phx.server
   ```

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.

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

## Testing

Run tests with:

```bash
mix test
```

## Code Formatting

```bash
mix format
```

## Architecture

### Core Concepts

- **Apps**: Registered applications that are being traced
- **Contexts**: Bounded contexts within an application (e.g., Accounts, Billing, Orders)
- **Traces**: A single execution flow through multiple contexts
- **Events**: Individual operations within a trace
- **Visualizations**: Auto-generated or custom diagram layouts
- **Narrations**: AI-generated analysis of trace patterns

### Technology Stack

- **Backend**: Elixir + Phoenix Framework
- **Frontend**: Phoenix LiveView + Tailwind CSS
- **Database**: PostgreSQL
- **AI**: Claude API (Anthropic) or OpenAI
- **Visualization**: D3.js or similar

## Documentation

Comprehensive design documentation is available in the `docs/design/` directory:

- [00-implementation-roadmap.md](docs/design/00-implementation-roadmap.md) - Complete implementation plan
- [01-project-structure.md](docs/design/01-project-structure.md) - Folder and module layout
- [02-schemas-and-types.md](docs/design/02-schemas-and-types.md) - Database schema design
- [03-context-apis.md](docs/design/03-context-apis.md) - Business logic APIs
- [04-liveview-design.md](docs/design/04-liveview-design.md) - UI components and pages
- [05-instrumentation-client.md](docs/design/05-instrumentation-client.md) - Tracing library
- [06-ai-narration.md](docs/design/06-ai-narration.md) - LLM integration
- [07-demoshop-example-app.md](docs/design/07-demoshop-example-app.md) - Demo application

## Contributing

This project follows the Phoenix framework conventions and Elixir style guide.

## License

Copyright © 2025

---

**Status**: Phase 1 Complete - Ready for Phase 2 (Context APIs)
