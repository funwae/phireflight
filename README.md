# PhireFlight

PhireFlight is a Phoenix LiveView application for visualizing and analyzing distributed system traces. It provides an intuitive way to understand context boundaries, data flow, and architectural patterns in your applications.

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
   git clone <repository-url>
   cd phireflight
   ```

2. Install dependencies:
   ```bash
   mix deps.get
   ```

3. Create and migrate your database:
   ```bash
   mix ecto.setup
   ```

4. Install Node.js dependencies:
   ```bash
   cd assets && npm install && cd ..
   ```

5. Start the Phoenix server:
   ```bash
   mix phx.server
   ```

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.

## Configuration

### Database

Configure your database in `config/dev.exs` or set the `DATABASE_URL` environment variable.

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

## Documentation

See the `docs/design/` directory for comprehensive design documentation:

- [Implementation Roadmap](docs/design/00-implementation-roadmap.md)
- [Project Structure](docs/design/01-project-structure.md)
- [Schemas and Types](docs/design/02-schemas-and-types.md)
- [Context APIs](docs/design/03-context-apis.md)
- [LiveView Design](docs/design/04-liveview-design.md)
- [Instrumentation Client](docs/design/05-instrumentation-client.md)
- [AI Narration](docs/design/06-ai-narration.md)
- [DemoShop Example App](docs/design/07-demoshop-example-app.md)

## Architecture

PhireFlight uses a context-based architecture following Phoenix best practices:

- **Accounts**: User authentication and management
- **Apps**: Application registration and API keys
- **Contexts**: Bounded context definitions
- **Traces**: Trace lifecycle and metadata
- **TraceEvents**: Individual events within traces
- **Visualizations**: Layout management for diagrams
- **Narrations**: AI-generated trace analysis

## License

Copyright © 2025

## Contributing

This project is currently in active development. Contribution guidelines will be added once the MVP is complete.
