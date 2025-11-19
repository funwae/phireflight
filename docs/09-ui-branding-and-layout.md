# PhireFlight & CodeMySpec – UI Branding and Layout

This project now has TWO siblings:

- **PhireFlight** – the flaming phoenix passing through a camera frame.
- **CodeMySpec** – the Phoenix-in-`< >` code bracket mark.

The UI should feel like a coherent mini-ecosystem: opinionated, legible, and a bit dramatic — but not cute or toy-like.

---

## 1. Brand Pillars

1. **Clarity over Flash**
   PhireFlight visualizes complex behavior; the UI must reduce cognitive load, not add noise.

2. **Phoenix Energy**
   Use the phoenix orange as an accent: it should feel like hot lines on cool metal, not a lava lamp.

3. **Instrumentation, Not Marketing**
   This is a tool an Elixir engineer could live in. No fake gradients for their own sake. Every visual emphasis should map to meaning (active flight, error, selected context, etc.).

---

## 2. Core Visual Language

### 2.1 Colors (tailwind-style tokens)

You don't have to change Tailwind config now, but design as if these exist:

- `brand-bg` (dark slate): `#0b1016`
- `brand-bg-alt` (panel): `#141b24`
- `brand-border` (lines): `#1f2933`
- `brand-text` (primary text): `#e5edf7`
- `brand-muted` (secondary text): `#9aa6bf`
- `brand-accent` (phoenix orange): `#f97316` (or close to Phoenix orange)
- `brand-accent-soft` (glow): same orange at 20–30% opacity.

Implementation hint: use Tailwind utility classes like:

- `bg-slate-950`, `bg-slate-900`, `border-slate-800`
- `text-slate-100`, `text-slate-400`
- `text-orange-400`, `bg-orange-500/20` for highlights.

### 2.2 Typography

- **Primary font:** system sans (Tailwind `font-sans`), but style it like:
  - `text-sm` for body
  - `text-xl font-semibold` for section titles
  - `tracking-tight` for headings.

- Make headings terse:
  - "Flights"
  - "Contexts"
  - "Flight Timeline"
  - "AI Narration"

No lorem ipsum anywhere.

### 2.3 Iconography

- Use simple heroicons / lucide-style icons where helpful:
  - Airplane / activity icon for flights.
  - Boxes / grid for contexts.
  - Sparkles / brain for AI narration.

Keep icons line-based and subtle (no giant cartoon icons).

---

## 3. Layout Specs

### 3.1 Global Shell

Implement a consistent shell in `root.html.heex`:

- **Top nav bar** (height ~56–64px):
  - Left: small PhireFlight logo (use our PNG) + wordmark "PhireFlight".
  - Right: links:
    - "Apps"
    - "Flights"
    - "Demo"
    - optional avatar / placeholder.

- **Body**:
  - `max-w-6xl mx-auto px-4 py-6` for main pages.
  - Use a simple 12-column mental grid:
    - titles on top
    - content in 2-column or 3-column layouts as needed.

### 3.2 Apps Index (`/apps`)

Goal: feels like a control room.

Sections:

1. **Page header**
   - Title: "Observed Phoenix Apps"
   - Subtitle: "Each app streams its flights into PhireFlight."

2. **Cards layout**
   - For each app, show a card with:
     - App name + small app icon.
     - Short description.
     - Stats row:
       - `X contexts`
       - `Y flights (24h)`
     - "View flights" button (primary).

Use a responsive grid: Tailwind `grid grid-cols-1 md:grid-cols-2 gap-4`.

### 3.3 App Detail (`/apps/:id`)

Two-column layout:

- **Left column (approx 60%)**
  - Card: "Context Map"
    - List of contexts as pill-like rows:
      - Name
      - Kind (Domain / Integration / UI)
      - Short description.
    - Indicate if a context was used in the last 24h (dot with brand accent).

- **Right column (approx 40%)**
  - Card: "Recent Flights"
    - Table with:
      - timestamp
      - entry point (e.g. `POST /checkout`)
      - status badge (green/amber/red)
      - duration ms
      - "View flight" icon button.

Keep it very legible, no noise.

### 3.4 Flight Replay (`/apps/:app_id/traces/:trace_id`)

This is the signature screen. It should feel like a focusing viewfinder on the Phoenix.

Layout:

- **Top bar in content**
  - Left:
    - Title: "Flight #<short-id>"
    - Subtext: `POST /checkout • 132ms • 200 OK` with subtle separators.
  - Right:
    - Status pill: `OK`, `ERROR`, etc.
    - Button: "Generate narration" (if AI enabled).
    - Button: "Start guided demo" (if in demo mode – see demo doc).

- **Main area**: two-panels layout on desktop, stacked on mobile.

  1. **Left Panel – Context Diagram**
     - Container with dark background (`bg-slate-900 rounded-xl p-4`).
     - Each context is a node (rounded pill/rectangle) with:
       - context name
       - small colored dot (brand-accent) if active in this flight.
     - Edges/lines:
       - Represent transitions between contexts as stepped lines.
       - Highlight the current step when user hovers over timeline.
     - Optional: simple animation that reveals steps one by one.

  2. **Right Panel – Timeline & Narration**
     - Top: "Flight Timeline"
       - List each event as:
         - `T+0ms` – `Accounts.load_user/1`
         - `T+4ms` – `Checkout.create_order/1`, etc.
       - Use alternating background stripes for readability.
       - Indicate errors with a red dot and label.
     - Bottom: "AI Narration"
       - Cards:
         - Summary text.
         - List of issues with severity tags.

Spacing: generous – this is the hero. Avoid cramming; trust scrolling.

---

## 4. Animations and Diagram Behavior

We want tasteful, meaningful motion:

- On initial load of a flight:
  - Animate context nodes fading in (`opacity` + slight `translate-y`).

- When hovering / clicking a timeline row:
  - Highlight corresponding context node and edge with:
    - thicker border
    - brighter accent color
    - maybe a subtle glow (box-shadow / ring).

No autoplay crazy animation loops. The most important thing is that interaction is **predictable** and supports understanding.

---

## 5. CodeMySpec Visual Alignment

CodeMySpec will have its own site, but visually we want:

- Shared **phoenix orange accent**, similar typography.
- Use the `< CodeMySpec />` logo (phoenix bird as the "/") in the footer or "powered by" spot for any spec integration.
- If you add any "Learn more about CodeMySpec" links, give them a simple, understated card design – PhireFlight is the star here.

---

## 6. Implementation Notes

- Use existing Tailwind setup; prefer Tailwind utilities over custom CSS when possible.
- Don't break any current layout that's already functional; we are **enhancing**, not rewriting from scratch.
- Encapsulate Flight Diagram into a dedicated LiveComponent (e.g. `PhireFlightWeb.FlightDiagramComponent`) so we can iterate later without touching everything.

