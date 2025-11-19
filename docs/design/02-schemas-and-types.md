# PhireFlight Schemas and Types

## Overview
This document defines all Ecto schemas, field types, associations, indexes, and constraints.

---

## PhireFlight.Accounts.User

**File:** `lib/phireflight/accounts/user.ex`

### Schema Definition

```elixir
defmodule PhireFlight.Accounts.User do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "users" do
    field :email, :string
    field :name, :string
    field :hashed_password, :string
    field :confirmed_at, :naive_datetime
    field :password, :string, virtual: true, redact: true
    field :current_password, :string, virtual: true, redact: true

    has_many :apps, PhireFlight.Apps.App, foreign_key: :owner_id
    has_many :visualization_layouts, PhireFlight.Visualizations.VisualizationLayout

    timestamps(type: :utc_datetime)
  end

  # Validations, registration, password logic, etc.
end
```

### Database Fields

| Field | Type | Null? | Default | Notes |
|-------|------|-------|---------|-------|
| id | uuid | NO | gen_random_uuid() | Primary key |
| email | varchar(160) | NO | | Unique, case-insensitive |
| name | varchar(255) | YES | | Display name |
| hashed_password | varchar(255) | NO | | Bcrypt hash |
| confirmed_at | timestamp | YES | | Email confirmation |
| inserted_at | timestamp | NO | now() | |
| updated_at | timestamp | NO | now() | |

### Indexes
- `CREATE UNIQUE INDEX users_email_index ON users (LOWER(email))`

### Constraints
- Email format validation in changeset
- Password minimum length: 12 characters
- Email required, unique

---

## PhireFlight.Apps.App

**File:** `lib/phireflight/apps/app.ex`

### Schema Definition

```elixir
defmodule PhireFlight.Apps.App do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "apps" do
    field :name, :string
    field :slug, :string
    field :api_key, :string
    field :description, :string
    field :active, :boolean, default: true

    belongs_to :owner, PhireFlight.Accounts.User
    has_many :app_contexts, PhireFlight.Contexts.AppContext
    has_many :traces, PhireFlight.Traces.Trace
    has_many :visualization_layouts, PhireFlight.Visualizations.VisualizationLayout

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(app, attrs) do
    app
    |> cast(attrs, [:name, :slug, :description, :active, :owner_id])
    |> validate_required([:name, :slug, :owner_id])
    |> validate_length(:name, min: 1, max: 100)
    |> validate_length(:slug, min: 1, max: 100)
    |> validate_format(:slug, ~r/^[a-z0-9-]+$/)
    |> unique_constraint(:slug)
    |> put_api_key()
  end

  defp put_api_key(changeset) do
    if get_field(changeset, :api_key) do
      changeset
    else
      put_change(changeset, :api_key, generate_api_key())
    end
  end

  defp generate_api_key do
    :crypto.strong_rand_bytes(32) |> Base.url_encode64(padding: false)
  end
end
```

### Database Fields

| Field | Type | Null? | Default | Notes |
|-------|------|-------|---------|-------|
| id | uuid | NO | gen_random_uuid() | Primary key |
| name | varchar(100) | NO | | Display name |
| slug | varchar(100) | NO | | URL-friendly identifier |
| api_key | varchar(64) | NO | | For external instrumentation |
| description | text | YES | | Plain text description |
| active | boolean | NO | true | Soft delete flag |
| owner_id | uuid | NO | | FK to users.id |
| inserted_at | timestamp | NO | now() | |
| updated_at | timestamp | NO | now() | |

### Indexes
- `CREATE UNIQUE INDEX apps_slug_index ON apps (slug)`
- `CREATE INDEX apps_owner_id_index ON apps (owner_id)`
- `CREATE UNIQUE INDEX apps_api_key_index ON apps (api_key)`

### Constraints
- `FOREIGN KEY (owner_id) REFERENCES users(id) ON DELETE CASCADE`

---

## PhireFlight.Contexts.AppContext

**File:** `lib/phireflight/contexts/app_context.ex`

### Schema Definition

```elixir
defmodule PhireFlight.Contexts.AppContext do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "app_contexts" do
    field :name, :string
    field :full_name, :string
    field :description, :string
    field :kind, Ecto.Enum, values: [:domain, :integration, :ui, :infra]
    field :color, :string
    field :position, :integer

    belongs_to :app, PhireFlight.Apps.App
    has_many :trace_events, PhireFlight.TraceEvents.TraceEvent

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(app_context, attrs) do
    app_context
    |> cast(attrs, [:name, :full_name, :description, :kind, :color, :position, :app_id])
    |> validate_required([:name, :app_id])
    |> validate_length(:name, min: 1, max: 100)
    |> validate_format(:color, ~r/^#[0-9A-Fa-f]{6}$/, message: "must be a valid hex color")
    |> unique_constraint([:app_id, :name])
  end
end
```

### Database Fields

| Field | Type | Null? | Default | Notes |
|-------|------|-------|---------|-------|
| id | uuid | NO | gen_random_uuid() | Primary key |
| app_id | uuid | NO | | FK to apps.id |
| name | varchar(100) | NO | | e.g. "Accounts" |
| full_name | varchar(255) | YES | | e.g. "DemoShop.Accounts" |
| description | text | YES | | What this context owns |
| kind | varchar(20) | NO | 'domain' | domain/integration/ui/infra |
| color | varchar(7) | YES | | Hex color for diagrams |
| position | integer | YES | | Display order |
| inserted_at | timestamp | NO | now() | |
| updated_at | timestamp | NO | now() | |

### Indexes
- `CREATE UNIQUE INDEX app_contexts_app_id_name_index ON app_contexts (app_id, name)`
- `CREATE INDEX app_contexts_app_id_index ON app_contexts (app_id)`

### Constraints
- `FOREIGN KEY (app_id) REFERENCES apps(id) ON DELETE CASCADE`
- `CHECK (kind IN ('domain', 'integration', 'ui', 'infra'))`

---

## PhireFlight.Traces.Trace

**File:** `lib/phireflight/traces/trace.ex`

### Schema Definition

```elixir
defmodule PhireFlight.Traces.Trace do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "traces" do
    field :external_id, :string
    field :entry_point, :string
    field :request_method, :string
    field :request_path, :string
    field :status, Ecto.Enum, values: [:ok, :error, :timeout, :cancelled], default: :ok
    field :started_at, :utc_datetime
    field :finished_at, :utc_datetime
    field :duration_ms, :integer
    field :error_class, :string
    field :error_message, :string
    field :metadata, :map

    belongs_to :app, PhireFlight.Apps.App
    has_many :trace_events, PhireFlight.TraceEvents.TraceEvent
    has_one :narration, PhireFlight.Narrations.Narration

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(trace, attrs) do
    trace
    |> cast(attrs, [
      :external_id,
      :entry_point,
      :request_method,
      :request_path,
      :status,
      :started_at,
      :finished_at,
      :duration_ms,
      :error_class,
      :error_message,
      :metadata,
      :app_id
    ])
    |> validate_required([:entry_point, :started_at, :app_id])
    |> validate_inclusion(:status, [:ok, :error, :timeout, :cancelled])
    |> foreign_key_constraint(:app_id)
  end

  def finish_changeset(trace, attrs) do
    changeset(trace, attrs)
    |> put_duration()
  end

  defp put_duration(changeset) do
    started = get_field(changeset, :started_at)
    finished = get_field(changeset, :finished_at)

    if started && finished do
      duration = DateTime.diff(finished, started, :millisecond)
      put_change(changeset, :duration_ms, duration)
    else
      changeset
    end
  end
end
```

### Database Fields

| Field | Type | Null? | Default | Notes |
|-------|------|-------|---------|-------|
| id | uuid | NO | gen_random_uuid() | Primary key |
| app_id | uuid | NO | | FK to apps.id |
| external_id | varchar(255) | YES | | App's correlation ID |
| entry_point | varchar(500) | NO | | e.g. "GET /checkout" |
| request_method | varchar(10) | YES | | GET/POST/etc |
| request_path | varchar(500) | YES | | URL path |
| status | varchar(20) | NO | 'ok' | ok/error/timeout/cancelled |
| started_at | timestamp | NO | | Trace start time |
| finished_at | timestamp | YES | | Trace end time |
| duration_ms | integer | YES | | Computed duration |
| error_class | varchar(255) | YES | | Exception class |
| error_message | text | YES | | Exception message |
| metadata | jsonb | YES | | Extra data |
| inserted_at | timestamp | NO | now() | |
| updated_at | timestamp | NO | now() | |

### Indexes
- `CREATE INDEX traces_app_id_index ON traces (app_id)`
- `CREATE INDEX traces_started_at_index ON traces (started_at DESC)`
- `CREATE INDEX traces_status_index ON traces (status)`
- `CREATE INDEX traces_external_id_index ON traces (external_id)` (for lookups)

### Constraints
- `FOREIGN KEY (app_id) REFERENCES apps(id) ON DELETE CASCADE`
- `CHECK (status IN ('ok', 'error', 'timeout', 'cancelled'))`

---

## PhireFlight.TraceEvents.TraceEvent

**File:** `lib/phireflight/trace_events/trace_event.ex`

### Schema Definition

```elixir
defmodule PhireFlight.TraceEvents.TraceEvent do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "trace_events" do
    field :module, :string
    field :function, :string
    field :arity, :integer
    field :event_type, Ecto.Enum,
      values: [:context_call, :db_query, :external_call, :controller, :liveview, :job, :other],
      default: :other
    field :sequence_index, :integer
    field :started_at, :utc_datetime
    field :finished_at, :utc_datetime
    field :duration_ms, :integer
    field :metadata, :map
    field :error, :boolean, default: false
    field :error_message, :string

    belongs_to :trace, PhireFlight.Traces.Trace
    belongs_to :app_context, PhireFlight.Contexts.AppContext

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(trace_event, attrs) do
    trace_event
    |> cast(attrs, [
      :module,
      :function,
      :arity,
      :event_type,
      :sequence_index,
      :started_at,
      :finished_at,
      :duration_ms,
      :metadata,
      :error,
      :error_message,
      :trace_id,
      :app_context_id
    ])
    |> validate_required([:module, :function, :event_type, :sequence_index, :started_at, :trace_id])
    |> validate_number(:arity, greater_than_or_equal_to: 0)
    |> validate_number(:sequence_index, greater_than_or_equal_to: 0)
    |> foreign_key_constraint(:trace_id)
    |> foreign_key_constraint(:app_context_id)
  end
end
```

### Database Fields

| Field | Type | Null? | Default | Notes |
|-------|------|-------|---------|-------|
| id | uuid | NO | gen_random_uuid() | Primary key |
| trace_id | uuid | NO | | FK to traces.id |
| app_context_id | uuid | YES | | FK to app_contexts.id |
| module | varchar(255) | NO | | e.g. "DemoShop.Accounts" |
| function | varchar(255) | NO | | e.g. "create_user" |
| arity | integer | YES | | Function arity |
| event_type | varchar(30) | NO | 'other' | Type enum |
| sequence_index | integer | NO | | Order in trace |
| started_at | timestamp | NO | | Event start |
| finished_at | timestamp | YES | | Event end |
| duration_ms | integer | YES | | Computed duration |
| metadata | jsonb | YES | | Params, query, etc. |
| error | boolean | NO | false | Whether errored |
| error_message | text | YES | | Error details |
| inserted_at | timestamp | NO | now() | |
| updated_at | timestamp | NO | now() | |

### Indexes
- `CREATE INDEX trace_events_trace_id_index ON trace_events (trace_id)`
- `CREATE INDEX trace_events_app_context_id_index ON trace_events (app_context_id)`
- `CREATE INDEX trace_events_trace_id_sequence_index ON trace_events (trace_id, sequence_index)`
- `CREATE INDEX trace_events_module_index ON trace_events (module)`

### Constraints
- `FOREIGN KEY (trace_id) REFERENCES traces(id) ON DELETE CASCADE`
- `FOREIGN KEY (app_context_id) REFERENCES app_contexts(id) ON DELETE SET NULL`

---

## PhireFlight.Visualizations.VisualizationLayout

**File:** `lib/phireflight/visualizations/visualization_layout.ex`

### Schema Definition

```elixir
defmodule PhireFlight.Visualizations.VisualizationLayout do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "visualization_layouts" do
    field :name, :string
    field :layout_json, :map
    field :is_default, :boolean, default: false

    belongs_to :app, PhireFlight.Apps.App
    belongs_to :user, PhireFlight.Accounts.User

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(layout, attrs) do
    layout
    |> cast(attrs, [:name, :layout_json, :is_default, :app_id, :user_id])
    |> validate_required([:name, :layout_json, :app_id])
    |> validate_layout_structure()
    |> foreign_key_constraint(:app_id)
    |> foreign_key_constraint(:user_id)
  end

  defp validate_layout_structure(changeset) do
    # Validate JSON structure has required keys
    case get_change(changeset, :layout_json) do
      %{"nodes" => _nodes} = _layout ->
        changeset

      _ ->
        add_error(changeset, :layout_json, "must contain 'nodes' key")
    end
  end
end
```

### Database Fields

| Field | Type | Null? | Default | Notes |
|-------|------|-------|---------|-------|
| id | uuid | NO | gen_random_uuid() | Primary key |
| app_id | uuid | NO | | FK to apps.id |
| user_id | uuid | YES | | FK to users.id, null = global |
| name | varchar(100) | NO | | Layout name |
| layout_json | jsonb | NO | | Node positions, etc. |
| is_default | boolean | NO | false | Default for app/user |
| inserted_at | timestamp | NO | now() | |
| updated_at | timestamp | NO | now() | |

### Layout JSON Structure

```json
{
  "nodes": [
    {
      "context_id": "uuid",
      "x": 100,
      "y": 200,
      "width": 150,
      "height": 80
    }
  ],
  "viewport": {
    "zoom": 1.0,
    "center_x": 0,
    "center_y": 0
  }
}
```

### Indexes
- `CREATE INDEX visualization_layouts_app_id_index ON visualization_layouts (app_id)`
- `CREATE INDEX visualization_layouts_user_id_index ON visualization_layouts (user_id)`

### Constraints
- `FOREIGN KEY (app_id) REFERENCES apps(id) ON DELETE CASCADE`
- `FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE`

---

## PhireFlight.Narrations.Narration

**File:** `lib/phireflight/narrations/narration.ex`

### Schema Definition

```elixir
defmodule PhireFlight.Narrations.Narration do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "narrations" do
    field :model_name, :string
    field :summary, :string
    field :details, :string
    field :issues, {:array, :map}
    field :generation_time_ms, :integer

    belongs_to :trace, PhireFlight.Traces.Trace

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(narration, attrs) do
    narration
    |> cast(attrs, [:model_name, :summary, :details, :issues, :generation_time_ms, :trace_id])
    |> validate_required([:model_name, :summary, :trace_id])
    |> validate_length(:summary, max: 1000)
    |> foreign_key_constraint(:trace_id)
    |> unique_constraint(:trace_id)
  end
end
```

### Database Fields

| Field | Type | Null? | Default | Notes |
|-------|------|-------|---------|-------|
| id | uuid | NO | gen_random_uuid() | Primary key |
| trace_id | uuid | NO | | FK to traces.id |
| model_name | varchar(100) | NO | | e.g. "claude-3-5-sonnet" |
| summary | varchar(1000) | NO | | Short recap |
| details | text | YES | | Longer explanation |
| issues | jsonb | YES | | Array of issue objects |
| generation_time_ms | integer | YES | | How long LLM took |
| inserted_at | timestamp | NO | now() | |
| updated_at | timestamp | NO | now() | |

### Issues JSON Structure

```json
[
  {
    "type": "cross_context_leak",
    "severity": "warn",
    "description": "Billing called Repo directly instead of Orders context",
    "event_ids": ["uuid1", "uuid2"]
  }
]
```

### Indexes
- `CREATE UNIQUE INDEX narrations_trace_id_index ON narrations (trace_id)`

### Constraints
- `FOREIGN KEY (trace_id) REFERENCES traces(id) ON DELETE CASCADE`

---

## Ecto Enums

### PhireFlight.Contexts.ContextKind

```elixir
defmodule PhireFlight.Contexts.ContextKind do
  use Ecto.Type

  def type, do: :string

  def cast(value) when value in [:domain, :integration, :ui, :infra], do: {:ok, value}
  def cast(value) when is_binary(value) do
    case value do
      "domain" -> {:ok, :domain}
      "integration" -> {:ok, :integration}
      "ui" -> {:ok, :ui}
      "infra" -> {:ok, :infra}
      _ -> :error
    end
  end
  def cast(_), do: :error

  def load(value) when is_binary(value), do: cast(value)

  def dump(value) when value in [:domain, :integration, :ui, :infra] do
    {:ok, Atom.to_string(value)}
  end
  def dump(_), do: :error
end
```

### PhireFlight.Traces.TraceStatus

Values: `:ok`, `:error`, `:timeout`, `:cancelled`

### PhireFlight.TraceEvents.EventType

Values: `:context_call`, `:db_query`, `:external_call`, `:controller`, `:liveview`, `:job`, `:other`

---

## Summary

- **7 main schemas** for PhireFlight core
- **All use UUIDs** for primary keys
- **Proper foreign keys** with CASCADE/SET NULL
- **JSONB fields** for flexible metadata
- **Ecto enums** for status/type fields
- **Timestamps** on all tables
- **Indexes** on foreign keys, lookups, and common queries
