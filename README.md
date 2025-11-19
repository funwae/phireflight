# PhireFlight

**AI-Powered Application Context Flow Visualization**

PhireFlight is a Phoenix LiveView application that visualizes and analyzes how context boundaries interact across your application using AI-powered insights.

## Project Status

**Phase 0: Bootstrap - COMPLETE ✅**

The Phoenix application structure has been created manually with all core files in place.

### Completed

- ✅ Phoenix project structure created
- ✅ Configuration files (dev, test, prod, runtime)
- ✅ Core application modules (Application, Repo, Endpoint, Router)
- ✅ Web infrastructure (Controllers, Components, Layouts)
- ✅ Asset configuration (JavaScript, CSS, Tailwind)
- ✅ Test infrastructure (DataCase, ConnCase, test helpers)
- ✅ Empty context directories created for all planned contexts
- ✅ PostgreSQL installed and running

### Context Directories Created

```
lib/phireflight/
├── accounts/        # User authentication and management
├── apps/            # Registered applications
├── contexts/        # Application contexts
├── traces/          # Execution traces
├── trace_events/    # Individual trace events
├── visualizations/  # Diagram layouts
├── narrations/      # AI-generated insights
├── llm_client/      # LLM integration
└── instrumentation/ # Tracing client library
```

## Next Steps

### Before Running the Application

Due to network restrictions during bootstrap, the following steps need to be completed:

1. **Install Dependencies**
   ```bash
   mix local.rebar --force
   mix local.hex --force
   mix deps.get
   cd assets && npm install
   ```

2. **Create Database**
   ```bash
   mix ecto.create
   ```

3. **Generate Authentication** (Phase 0 optional task)
   ```bash
   mix phx.gen.auth Accounts User users
   ```

4. **Run the Application**
   ```bash
   mix phx.server
   ```

   Visit http://localhost:4000

### Implementation Phases

- **Phase 0**: Project Bootstrap ✅ **(COMPLETE)**
- **Phase 1**: Core Data Models (schemas and migrations)
- **Phase 2**: Context APIs (business logic)
- **Phase 3**: Basic LiveView UI (apps, contexts, traces)
- **Phase 4**: Instrumentation Client (tracing library)
- **Phase 5**: DemoShop Application (example e-commerce app)
- **Phase 6**: Flight Replay Visualization (interactive diagrams)
- **Phase 7**: AI Narration System (LLM integration)
- **Phase 8**: Polish & Demo Prep

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

## Development

### Prerequisites

- Elixir 1.14+
- Erlang/OTP 25+
- PostgreSQL 14+
- Node.js 16+ (for assets)

### Database Configuration

Update config/dev.exs with your PostgreSQL credentials:

```elixir
config :phireflight, PhireFlight.Repo,
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  database: "phireflight_dev"
```

### Running Tests

```bash
mix test
```

### Code Formatting

```bash
mix format
```

## Contributing

This project follows the Phoenix framework conventions and Elixir style guide.

## License

Copyright © 2025

---

**Status**: Phase 0 Complete - Ready for Phase 1 (Core Data Models)
