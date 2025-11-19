# PhireFlight Implementation Roadmap

## Design Documents Summary

This directory contains the complete design specifications for PhireFlight. All documents are ready for implementation.

### Document Index

1. **[01-project-structure.md](01-project-structure.md)** - Complete folder/module layout
2. **[02-schemas-and-types.md](02-schemas-and-types.md)** - All Ecto schemas, fields, and database design
3. **[03-context-apis.md](03-context-apis.md)** - Public API for all Phoenix contexts
4. **[04-liveview-design.md](04-liveview-design.md)** - LiveView modules, components, and UI
5. **[05-instrumentation-client.md](05-instrumentation-client.md)** - Tracing client library design
6. **[06-ai-narration.md](06-ai-narration.md)** - LLM integration and prompt engineering
7. **[07-demoshop-example-app.md](07-demoshop-example-app.md)** - Demo application structure

---

## Implementation Phases

### Phase 0: Project Bootstrap (Foundation)

**Goal:** Get the Phoenix app running with basic structure.

**Tasks:**

- [ ] Create new Phoenix project with LiveView
- [ ] Set up PostgreSQL database
- [ ] Configure Tailwind CSS
- [ ] Set up basic authentication (phx.gen.auth)
- [ ] Create empty context directories
- [ ] Set up testing infrastructure
- [ ] Configure mix dependencies

**Files to create:**

```
mix.exs
config/config.exs
config/dev.exs
config/test.exs
config/prod.exs
config/runtime.exs
lib/phireflight.ex
lib/phireflight/application.ex
lib/phireflight/repo.ex
lib/phireflight_web.ex
lib/phireflight_web/router.ex
lib/phireflight_web/endpoint.ex
```

**Commands:**

```bash
mix phx.new phireflight --live
cd phireflight
mix ecto.create
mix phx.gen.auth Accounts User users
```

**Estimated time:** 2-4 hours

---

### Phase 1: Core Data Models

**Goal:** Implement all schemas and migrations.

**Tasks:**

- [ ] Create Users schema (from phx.gen.auth)
- [ ] Create Apps schema and migration
- [ ] Create AppContexts schema and migration
- [ ] Create Traces schema and migration
- [ ] Create TraceEvents schema and migration
- [ ] Create VisualizationLayouts schema and migration
- [ ] Create Narrations schema and migration
- [ ] Run migrations
- [ ] Test all schemas with basic CRUD

**Migrations to create:**

```
priv/repo/migrations/YYYYMMDDHHMMSS_create_apps.exs
priv/repo/migrations/YYYYMMDDHHMMSS_create_app_contexts.exs
priv/repo/migrations/YYYYMMDDHHMMSS_create_traces.exs
priv/repo/migrations/YYYYMMDDHHMMSS_create_trace_events.exs
priv/repo/migrations/YYYYMMDDHHMMSS_create_visualization_layouts.exs
priv/repo/migrations/YYYYMMDDHHMMSS_create_narrations.exs
```

**Reference:** `docs/design/02-schemas-and-types.md`

**Estimated time:** 4-6 hours

---

### Phase 2: Context APIs

**Goal:** Implement all context business logic.

**Tasks:**

- [ ] Implement PhireFlight.Accounts (basic CRUD)
- [ ] Implement PhireFlight.Apps
- [ ] Implement PhireFlight.Contexts
- [ ] Implement PhireFlight.Traces
- [ ] Implement PhireFlight.TraceEvents
- [ ] Implement PhireFlight.Visualizations
- [ ] Implement PhireFlight.Narrations (without LLM first)
- [ ] Write unit tests for all contexts
- [ ] Set up fixtures for testing

**Files to create:**

```
lib/phireflight/apps/app.ex
lib/phireflight/apps/apps.ex
lib/phireflight/contexts/app_context.ex
lib/phireflight/contexts/contexts.ex
lib/phireflight/traces/trace.ex
lib/phireflight/traces/traces.ex
lib/phireflight/trace_events/trace_event.ex
lib/phireflight/trace_events/trace_events.ex
lib/phireflight/visualizations/visualization_layout.ex
lib/phireflight/visualizations/visualizations.ex
lib/phireflight/narrations/narration.ex
lib/phireflight/narrations/narrations.ex
```

**Reference:** `docs/design/03-context-apis.md`

**Estimated time:** 8-12 hours

---

### Phase 3: Basic LiveView UI

**Goal:** Create functional UI for apps, contexts, and traces (no diagram yet).

**Tasks:**

- [ ] Set up router with all routes
- [ ] Implement AppsLive.Index
- [ ] Implement AppsLive.Show
- [ ] Implement AppsLive.FormComponent
- [ ] Implement ContextsLive.Index
- [ ] Implement ContextsLive.FormComponent
- [ ] Implement TracesLive.Index
- [ ] Implement TracesLive.Show (simple list view)
- [ ] Create reusable components (StatusBadge, ContextCard)
- [ ] Style with Tailwind
- [ ] Test in browser

**Files to create:**

```
lib/phireflight_web/live/apps_live/index.ex
lib/phireflight_web/live/apps_live/show.ex
lib/phireflight_web/live/apps_live/form_component.ex
lib/phireflight_web/live/contexts_live/index.ex
lib/phireflight_web/live/contexts_live/form_component.ex
lib/phireflight_web/live/traces_live/index.ex
lib/phireflight_web/live/traces_live/show.ex
lib/phireflight_web/components/status_badge.ex
lib/phireflight_web/components/context_card.ex
```

**Reference:** `docs/design/04-liveview-design.md`

**Estimated time:** 8-12 hours

---

### Phase 4: Instrumentation Client

**Goal:** Build the tracing client library.

**Tasks:**

- [ ] Implement PhireFlight.Instrumentation.Client
- [ ] Implement PhireFlight.Instrumentation.Plug
- [ ] Write comprehensive tests
- [ ] Document usage
- [ ] Create simple example (not DemoShop yet)

**Files to create:**

```
lib/phireflight/instrumentation/client.ex
lib/phireflight/instrumentation/plug.ex
lib/phireflight/instrumentation/storage.ex
test/phireflight/instrumentation/client_test.exs
```

**Reference:** `docs/design/05-instrumentation-client.md`

**Estimated time:** 6-8 hours

---

### Phase 5: DemoShop Application

**Goal:** Build the demo e-commerce app.

**Tasks:**

- [ ] Create DemoShop schemas (User, Product, Cart, Order, etc.)
- [ ] Run DemoShop migrations
- [ ] Implement DemoShop.Accounts context
- [ ] Implement DemoShop.Catalog context
- [ ] Implement DemoShop.Checkout context
- [ ] Implement DemoShop.Orders context
- [ ] Implement DemoShop.Billing context
- [ ] Add instrumentation to all contexts
- [ ] Create basic controllers/LiveViews
- [ ] Create seed data
- [ ] Test end-to-end checkout flow
- [ ] Verify traces appear in PhireFlight

**Files to create:**

```
priv/repo/migrations/YYYYMMDDHHMMSS_create_demo_shop_tables.exs
lib/demo_shop/accounts/user.ex
lib/demo_shop/accounts/accounts.ex
lib/demo_shop/catalog/product.ex
lib/demo_shop/catalog/cart.ex
lib/demo_shop/catalog/catalog.ex
lib/demo_shop/checkout/checkout.ex
lib/demo_shop/orders/order.ex
lib/demo_shop/orders/orders.ex
lib/demo_shop/billing/payment.ex
lib/demo_shop/billing/billing.ex
lib/demo_shop_web/controllers/product_controller.ex
lib/demo_shop_web/controllers/checkout_controller.ex
priv/repo/seeds.exs
```

**Reference:** `docs/design/07-demoshop-example-app.md`

**Estimated time:** 10-14 hours

---

### Phase 6: Flight Replay Visualization

**Goal:** Build the interactive trace diagram.

**Tasks:**

- [ ] Create TraceDiagram component
- [ ] Create TraceTimeline component
- [ ] Implement JavaScript hook for diagram rendering
- [ ] Add D3.js or similar for graph visualization
- [ ] Implement playback controls
- [ ] Add event selection/highlighting
- [ ] Make it responsive
- [ ] Test with real DemoShop traces

**Files to create:**

```
lib/phireflight_web/components/trace_diagram.ex
lib/phireflight_web/components/trace_timeline.ex
assets/js/hooks/trace_diagram.js
assets/js/hooks/timeline_player.js
```

**Reference:** `docs/design/04-liveview-design.md`

**Estimated time:** 8-12 hours

---

### Phase 7: AI Narration System

**Goal:** Integrate LLM for trace analysis.

**Tasks:**

- [ ] Implement LLMClient.Behaviour
- [ ] Implement LLMClient.Mock (for tests)
- [ ] Implement LLMClient.Claude
- [ ] Implement LLMClient.OpenAI (optional)
- [ ] Implement Narrations.Generator
- [ ] Implement Narrations.PromptBuilder
- [ ] Wire up "Generate Narration" button in UI
- [ ] Test with real traces
- [ ] Tune prompts for better results
- [ ] Add error handling for API failures

**Files to create:**

```
lib/phireflight/llm_client/behaviour.ex
lib/phireflight/llm_client/llm_client.ex
lib/phireflight/llm_client/claude.ex
lib/phireflight/llm_client/openai.ex
lib/phireflight/llm_client/mock.ex
lib/phireflight/narrations/generator.ex
lib/phireflight/narrations/prompt_builder.ex
lib/phireflight_web/components/narration_panel.ex
```

**Reference:** `docs/design/06-ai-narration.md`

**Estimated time:** 8-10 hours

---

### Phase 8: Polish & Demo Prep

**Goal:** Make it demo-ready.

**Tasks:**

- [ ] Add visualization layout auto-generation
- [ ] Improve UI styling and animations
- [ ] Add loading states
- [ ] Add error handling throughout
- [ ] Write comprehensive README
- [ ] Create demo script/walkthrough
- [ ] Record demo video (optional)
- [ ] Deploy to staging (optional)
- [ ] Performance testing
- [ ] Bug fixes

**Estimated time:** 6-10 hours

---

## Total Estimated Time

**Minimum:** 60 hours
**Maximum:** 88 hours
**Average:** 74 hours (~2 weeks full-time, 4-6 weeks part-time)

---

## Key Dependencies

### Elixir/Phoenix

```elixir
{:phoenix, "~> 1.7.14"},
{:phoenix_ecto, "~> 4.5"},
{:ecto_sql, "~> 3.11"},
{:postgrex, ">= 0.0.0"},
{:phoenix_live_view, "~> 0.20.17"},
{:tailwind, "~> 0.2"},
{:heroicons, github: "tailwindlabs/heroicons"},
{:jason, "~> 1.4"},
{:req, "~> 0.4.0"},        # HTTP client for LLM APIs
{:uuid, "~> 1.1"}          # Trace ID generation
```

### JavaScript

```json
{
  "d3": "^7.0.0",           // For diagram visualization
  "alpinejs": "^3.0.0"      // Optional: For interactive components
}
```

### External Services

- PostgreSQL 14+
- Claude API (Anthropic) or OpenAI API
- (Optional) Deployment platform (Fly.io, Heroku, etc.)

---

## Development Workflow

### 1. Start Each Phase

```bash
# Create a feature branch
git checkout -b phase-X-description

# Work on tasks
# Commit frequently
# Write tests as you go
```

### 2. Testing Strategy

- Unit tests for all contexts
- Integration tests for flows
- LiveView tests for UI
- Manual testing in browser

### 3. Git Commits

Follow conventional commits:

```
feat: add Apps context with CRUD operations
test: add unit tests for Traces context
fix: correct trace duration calculation
docs: update API documentation for TraceEvents
```

### 4. Pull Requests

- One PR per phase (or smaller if preferred)
- Include screenshots for UI changes
- Update docs if behavior changes

---

## Success Criteria

### MVP is complete when:

- ✅ Can create apps and contexts in UI
- ✅ DemoShop checkout generates a trace
- ✅ Trace appears in PhireFlight UI
- ✅ Can view trace with diagram and timeline
- ✅ Can generate AI narration for a trace
- ✅ Narration identifies the "bad checkout" anti-patterns
- ✅ All tests pass
- ✅ README has clear setup instructions

### Demo is successful when:

- 🎯 Can show it to someone and they say "no way, that's insane"
- 🎯 AI correctly identifies architectural issues
- 🎯 Diagram clearly shows context flow
- 🎯 Can explain value prop in 2 minutes

---

## Next Steps

After reading all design docs, you should:

1. **Review** - Make sure you understand all components
2. **Question** - Ask about anything unclear
3. **Prioritize** - Decide if you want to adjust phase order
4. **Begin** - Start with Phase 0 (project bootstrap)

Ready to start scaffolding the code? Let me know and we'll begin with Phase 0!

---

## Quick Reference

### File Count by Phase

- Phase 0: ~10 files (Phoenix basics)
- Phase 1: ~14 files (migrations + schemas)
- Phase 2: ~14 files (context implementations)
- Phase 3: ~12 files (LiveView UI)
- Phase 4: ~4 files (instrumentation)
- Phase 5: ~15 files (DemoShop)
- Phase 6: ~4 files (visualization)
- Phase 7: ~8 files (AI narration)
- Phase 8: ~5 files (polish)

**Total: ~86 files** (not counting tests, which roughly doubles it)

### LOC Estimates

- Schemas: ~1,500 lines
- Contexts: ~2,500 lines
- LiveView: ~2,000 lines
- Instrumentation: ~800 lines
- DemoShop: ~1,500 lines
- AI/LLM: ~1,000 lines
- Tests: ~3,000 lines
- Misc: ~500 lines

**Total: ~13,000 lines of code**

This is a substantial but achievable project. The design is complete and ready for implementation.
