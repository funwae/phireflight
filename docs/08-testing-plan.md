# PhireFlight Testing Plan

PhireFlight is NOT a toy. This document defines the bar for "done":

- DemoShop flows work end-to-end.
- PhireFlight reliably records and displays flights.
- The core "wow" demo can be repeated without surprises.

We use **both**: (1) a manual test checklist for humans, and (2) automated tests in ExUnit (including LiveView tests).

---

## 1. Manual Test Checklist

Run this checklist before any demo or major change.

### 1.1 Environment Setup

- [ ] `mix deps.get` succeeds.
- [ ] `mix ecto.create` and `mix ecto.migrate` run without errors.
- [ ] `mix run priv/repo/seeds.exs` finishes successfully.
- [ ] `mix phx.server` boots with no warnings or errors in the console.

### 1.2 DemoShop – Happy Path Checkout

1. [ ] Visit `http://localhost:4000/demo/products`.
2. [ ] Confirm product listing appears with seeded products.
3. [ ] Add an item to cart and see confirmation / cart count update.
4. [ ] Proceed to checkout page.
5. [ ] Complete a **successful** checkout using the "good" path:
   - [ ] Form submits.
   - [ ] You see a success page / order confirmation.
   - [ ] No errors in the browser console or server logs.

### 1.3 DemoShop – Bad Checkout Flow

1. [ ] From products/cart, trigger the **bad** checkout scenario (out-of-stock / invalid data / whatever is wired up).
2. [ ] Confirm:
   - [ ] The UI shows an error or failure state (not a crash).
   - [ ] You remain in a sensible page (no 500 error page).
   - [ ] Logs show the expected error / failure but app keeps running.

### 1.4 PhireFlight – Flights Appear

For each of the two flows above:

1. [ ] Open PhireFlight main app list (`/apps`).
2. [ ] Open the **DemoShop** app.
3. [ ] In the recent flights section:
   - [ ] A new flight appears for each run.
   - [ ] Entry point, status, and timestamps look correct (e.g. `POST /checkout`).
4. [ ] Open each flight:
   - [ ] The context diagram renders.
   - [ ] Timeline shows ordered steps.
   - [ ] The "bad" flight clearly differs from the "good" one (extra step, error marker, etc.).

### 1.5 AI Narration (if wired)

- [ ] On at least one flight, click "Generate narration".
- [ ] A summary and issues list appear.
- [ ] Text is coherent and correctly references contexts and operations.
- [ ] No unhandled errors when the LLM call fails (human-friendly error message is shown).

### 1.6 Demo Mode / Guided Tour

- [ ] From the main UI, you can start a guided demo mode (see Demo doc).
- [ ] The tour walks through:
  - DemoShop entry
  - Triggering a flight
  - Viewing the flight in PhireFlight
- [ ] Tooltips or copy make sense and can be followed by a newcomer.

---

## 2. Automated Tests

We use ExUnit (+ Phoenix LiveView tests) for core guarantees.

### 2.1 DemoShop Tests

Create tests in `test/demoshop` (or equivalent) to cover:

- [ ] **Contexts:**
  - `DemoShop.Accounts` – basic user creation / retrieval.
  - `DemoShop.Catalog` – listing products, fetching product, adding to cart.
  - `DemoShop.Checkout` / `Billing` / `Orders` – happy path for creating an order.
- [ ] **Controllers / LiveViews (if present):**
  - Product listing renders successfully.
  - Checkout page renders.
  - Submitting a valid checkout request results in a persisted order.

Goal: if any core domain function regresses, tests fail.

### 2.2 PhireFlight Core Tests

Create tests in `test/phireflight` for:

- [ ] `PhireFlight.Traces` context:
  - Creating a trace (`start_trace`) persists a record with expected fields.
  - `finish_trace` updates status, finished_at, and duration.
- [ ] `PhireFlight.TraceEvents` context:
  - Recording steps appends events with correct sequence_index.
- [ ] Relationships:
  - Deleting an app cascades or rejects when there are traces (choose one behavior, document it).

### 2.3 LiveView UI Tests

Use `Phoenix.LiveViewTest` to cover:

- [ ] `/apps` index:
  - Renders list of apps.
  - Shows counts of contexts and flights for DemoShop.
- [ ] `/apps/:id` app show:
  - Lists recent flights.
  - Clicking a flight link navigates to the flight show page.
- [ ] `/apps/:app_id/traces/:trace_id` flight show:
  - Renders context diagram container.
  - Renders timeline entries for known events.
  - Renders status and entry point.

These don't need pixel-level checks; focus on **presence of data** and **non-crashing render**.

### 2.4 Narration Module Tests (if AI wired)

- [ ] `PhireFlight.Narrations.build_prompt(trace)` returns a structured prompt.
- [ ] When given a fake LLM client that returns known JSON, we persist a `Narration` struct with:
  - correct `trace_id`
  - non-empty `summary`
  - parsed `issues`.

Use behaviors + test adapters so tests don't call real APIs.

---

## 3. CI-Friendly Commands

Standard suite:

- `mix test` – run all tests.
- `MIX_ENV=test mix ecto.create && MIX_ENV=test mix ecto.migrate` before tests.

We should be able to say:

**"If `mix test` is green and the manual checklist passes, PhireFlight is demo-ready."**

