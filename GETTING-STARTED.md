# Getting Started with PhireFlight - Simple Guide

This guide will help you get PhireFlight running on your local machine, even if you're new to Elixir/Phoenix.

## What You Need

PhireFlight is a Phoenix (Elixir) web application. You don't need Docker - you can run it directly on your machine. Here's what you need:

1. **Elixir** (the programming language)
2. **PostgreSQL** (the database)
3. **Node.js** (for frontend assets)

## Step-by-Step Setup

### Step 1: Install Elixir

**On Ubuntu/Debian:**
```bash
# Install Erlang and Elixir
sudo apt-get update
sudo apt-get install -y elixir erlang-dev erlang-parsetools build-essential
```

**On macOS (using Homebrew):**
```bash
brew install elixir
```

**On Windows:**
Download the installer from: https://elixir-lang.org/install.html

**Verify installation:**
```bash
elixir --version
# Should show something like: Elixir 1.14.0 (or higher)
```

### Step 2: Install PostgreSQL

**On Ubuntu/Debian:**
```bash
sudo apt-get install -y postgresql postgresql-contrib
sudo systemctl start postgresql
```

**On macOS:**
```bash
brew install postgresql
brew services start postgresql
```

**On Windows:**
Download from: https://www.postgresql.org/download/windows/

**Verify installation:**
```bash
psql --version
# Should show: psql (PostgreSQL) 14.x or higher
```

### Step 3: Install Node.js

**On Ubuntu/Debian:**
```bash
# Install Node.js 18+ (using NodeSource repository)
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt-get install -y nodejs
```

**On macOS:**
```bash
brew install node
```

**On Windows:**
Download from: https://nodejs.org/

**Verify installation:**
```bash
node --version
# Should show: v18.x.x or higher
```

### Step 4: Set Up the Database

**Create a PostgreSQL user and databases:**

```bash
# Switch to postgres user
sudo -u postgres psql

# In the PostgreSQL prompt, run:
CREATE USER phireflight WITH PASSWORD 'phireflight123';
CREATE DATABASE phireflight_dev;
CREATE DATABASE phireflight_test;
GRANT ALL PRIVILEGES ON DATABASE phireflight_dev TO phireflight;
GRANT ALL PRIVILEGES ON DATABASE phireflight_test TO phireflight;
\q
```

**Or, if you want to use your existing postgres user:**
```bash
# Just create the databases
createdb phireflight_dev
createdb phireflight_test
```

### Step 5: Clone and Set Up the Project

```bash
# Clone the repository (if you haven't already)
git clone https://github.com/funwae/phireflight.git
cd phireflight

# Install Elixir dependencies
mix local.hex --force
mix local.rebar --force
mix deps.get

# Install Node.js dependencies
cd assets
npm install
cd ..
```

### Step 6: Configure the Database

Edit `config/dev.exs` and make sure the database settings match your PostgreSQL setup:

```elixir
config :phireflight, PhireFlight.Repo,
  username: "phireflight",  # or "postgres" if using default user
  password: "phireflight123",  # or your postgres password
  hostname: "localhost",
  database: "phireflight_dev"
```

### Step 7: Set Up the Database Schema

```bash
# Create the database tables
mix ecto.create
mix ecto.migrate

# Add some demo data
mix run priv/repo/seeds.exs
```

### Step 8: Start the Server

```bash
mix phx.server
```

You should see output like:
```
[info] Running PhireFlightWeb.Endpoint with Bandit 1.0.0 at 127.0.0.1:4000 (http)
[info] Access PhireFlightWeb.Endpoint at http://localhost:4000
```

### Step 9: Open in Your Browser

Visit: **http://localhost:4000**

You should see the PhireFlight home page!

## What to Do Next

1. **Explore the Demo App:**
   - Visit: http://localhost:4000/demo/products
   - Add items to cart and checkout
   - See how PhireFlight records the "flight"

2. **View Flights:**
   - Visit: http://localhost:4000/apps
   - Click on "DemoShop"
   - See the flights (traces) that were recorded

3. **Try Demo Mode:**
   - Visit: http://localhost:4000/demo/guide
   - Follow the guided tour

## Common Issues and Fixes

### "mix: command not found"
- Make sure Elixir is installed: `elixir --version`
- If installed but not found, you may need to restart your terminal

### "Database connection failed"
- Make sure PostgreSQL is running: `sudo systemctl status postgresql` (Linux) or `brew services list` (macOS)
- Check your database credentials in `config/dev.exs`
- Try creating the databases manually: `createdb phireflight_dev`

### "Port 4000 already in use"
- Another application is using port 4000
- Either stop that application, or change the port in `config/dev.exs`:
  ```elixir
  config :phireflight, PhireFlightWeb.Endpoint,
    http: [port: 4001]  # Change to a different port
  ```

### "Compilation errors"
- Make sure all system dependencies are installed:
  ```bash
  sudo apt-get install -y build-essential erlang-dev erlang-parsetools
  ```
- Clean and rebuild:
  ```bash
  mix clean
  mix deps.clean --all
  mix deps.get
  mix compile
  ```

### "Tests fail"
- Make sure the test database exists:
  ```bash
  MIX_ENV=test mix ecto.create
  MIX_ENV=test mix ecto.migrate
  ```

## Understanding the Project Structure

Here's a simple breakdown of what's where:

```
phireflight/
├── lib/
│   ├── phireflight/          # Core business logic (the "backend")
│   │   ├── apps/             # Managing registered apps
│   │   ├── traces/           # Managing flights/traces
│   │   └── instrumentation/ # The tracing library
│   ├── phireflight_web/      # Web interface (the "frontend")
│   │   ├── live/             # LiveView pages (interactive UI)
│   │   └── components/       # Reusable UI components
│   └── demo_shop/            # Demo e-commerce app
├── test/                      # Automated tests
├── config/                    # Configuration files
│   ├── dev.exs               # Development settings
│   └── test.exs             # Test settings
└── priv/repo/                 # Database migrations and seeds
```

## Key Concepts (Simplified)

- **Phoenix**: A web framework for Elixir (like Rails for Ruby, Django for Python)
- **LiveView**: Real-time interactive web pages without writing JavaScript
- **Contexts**: Phoenix's way of organizing business logic (like "Accounts", "Orders")
- **Flights**: PhireFlight's term for a request that flows through multiple contexts
- **Ecto**: The database library for Elixir (like ActiveRecord for Rails)

## Running Tests

```bash
# Set up test database
MIX_ENV=test mix ecto.create
MIX_ENV=test mix ecto.migrate

# Run all tests
mix test

# Run a specific test file
mix test test/phireflight/traces_test.exs
```

## Stopping the Server

Press `Ctrl+C` twice in the terminal where the server is running.

## Need Help?

- Check `handoff.md` for testing and verification steps
- Check `docs/08-testing-plan.md` for detailed testing information
- Check `README.md` for more technical details

## Quick Reference Commands

```bash
# Start fresh
mix clean
mix deps.get
mix ecto.reset  # Drops, creates, migrates, and seeds database
mix phx.server

# Run tests
MIX_ENV=test mix ecto.create
MIX_ENV=test mix ecto.migrate
mix test

# Format code
mix format

# Check what's running
mix phx.server  # Starts on http://localhost:4000
```

---

**That's it!** You should now have PhireFlight running locally. Start with the demo app to see it in action, then explore the code to understand how it works.

