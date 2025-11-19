# PhireFlight Demo Script & Demo Mode

PhireFlight must be easy to demo live, especially to Phoenix devs who have never seen it before. This doc defines:

1. A **spoken demo script** (for live calls / screen shares).
2. A built-in **Demo Mode** inside the UI that guides users through the same story.

---

## 1. Live Demo Script (v1)

Use DemoShop as the narrative.

### Opening (1–2 minutes)

1. **Context framing**

> "You know how Phoenix contexts are supposed to be the architectural backbone — but once AI and junior devs start pushing code, it's hard to see if the app still follows your context boundaries?
>
> PhireFlight is a flight recorder for Phoenix contexts. Every request becomes a 'flight' you can replay as a diagram and a story."

2. **Show DemoShop**

- Go to `http://localhost:4000/demo/products`.
- Briefly mention:
  - 5 contexts: Accounts, Catalog, Cart, Checkout, Billing/Orders.

### Happy Path Flight (3–4 minutes)

1. Add an item to cart.
2. Proceed to checkout and complete a **successful** order.
3. Switch to PhireFlight `/apps` → DemoShop → open the latest flight.

Narrate while showing:

- Context nodes lighting up:
  > "This was a single checkout request. We can see it flowed through Accounts → Catalog → Checkout → Billing → Orders."

- Timeline:
  > "Each row is a concrete function call in a specific context, with timing."

Optional: generate AI narration and read out the summary.

### Bad Path Flight (3–4 minutes)

1. Trigger the "bad" checkout: invalid data, payment failure, etc.
2. Open the corresponding flight.

Highlight differences:

- Extra steps or missing steps in the flow.
- An error marker in the timeline.
- Potential architecture smell (if you've wired up detection).

Explain:

> "The point isn't that this fails — failures are normal. The point is that you can now *see* the failure as a path through contexts, and even let an LLM summarize what happened for your teammates."

### Closing (1–2 minutes)

> "PhireFlight doesn't replace your tests or logs; it connects them to the architecture you *thought* you had.
> Today we're using a single Demo app, but the same pattern applies to any Phoenix system that respects contexts."

---

## 2. Demo Mode – UI Implementation

Demo Mode is a guided, self-service walkthrough that mirrors the script above.

### 2.1 Entry Points

- Add a **"Demo Mode"** button in:
  - `/` (home / apps index)
  - DemoShop page card ("Run demo").

Clicking it routes to e.g. `/demo/guide`.

### 2.2 Demo Guide Flow

Implement as a simple LiveView wizard (`DemoGuideLive`) with 3 steps:

1. **Step 1 – Welcome**
   - Explain what PhireFlight is in 2–3 sentences.
   - Buttons:
     - "Run happy path demo"
     - "Skip to flights"

2. **Step 2 – Trigger a Flight**
   - Show a split view:
     - Left: embed or link to DemoShop products page (`/demo/products`) with clear instruction:
       > "In the other tab/window, perform a checkout. When you're done, come back here and click 'I've completed a checkout'."
     - Right: a checklist:
       - Added item to cart
       - Completed checkout

   - Button: "I've completed a checkout". When clicked:
     - Poll for the most recent DemoShop flight and show a link to it.

3. **Step 3 – Explore the Flight**
   - Present the **Flight Replay** (reusing the usual page or embedding it).
   - Overlay a short textual tour:
     - "1. This diagram shows which contexts participated."
     - "2. This timeline shows the sequence of calls."
     - "3. Click 'Generate narration' to have the AI explain the flight."

   - Optional: highlight elements with simple callouts (CSS boxes with arrows).

### 2.3 Implementation Details

- Keep Demo Mode logic non-invasive:
  - Reuse existing queries for latest flights.
  - Avoid special "demo-only" code paths in core instrumentation.

- Make Demo Mode easy to disable:
  - Wrap the route in a config flag like `config :phireflight, demo_mode: true` (read at runtime).

---

## 3. Future Demo Enhancements (Not Required for v1)

- Pre-generated demo flights so first-time users see something even before running DemoShop.
- "Compare flights" view: happy vs bad path side-by-side.
- Exportable PDF/PNG of a flight diagram for sharing in architecture docs.

For the current phase, **implement the v1 demo script behavior and DemoGuideLive wizard**, ensuring it does not break any existing routes or flows.

