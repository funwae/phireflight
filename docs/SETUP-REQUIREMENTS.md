# PhireFlight Setup Requirements

## System Dependencies

To compile and run PhireFlight, you need the following system packages:

### Ubuntu/Debian

```bash
sudo apt-get update
sudo apt-get install -y build-essential erlang-dev erlang-parsetools
```

### Elixir Version

PhireFlight requires **Elixir 1.15+** for full compatibility with all dependencies (particularly `floki` for LiveView testing).

If you have Elixir 1.14, you may encounter compilation issues with `floki`. You can either:
1. Upgrade Elixir to 1.15+ (recommended)
2. Or skip test compilation for now and run tests after upgrading

### Current Status

- ✅ Elixir 1.14.0 installed
- ⚠️  Missing: `erlang-dev` (for NIF compilation - bcrypt_elixir)
- ⚠️  Missing: `erlang-parsetools` (for floki compilation)
- ⚠️  Elixir version: 1.14 (floki requires 1.15+)

## Quick Fix

Run these commands to install missing dependencies:

```bash
sudo apt-get update
sudo apt-get install -y build-essential erlang-dev erlang-parsetools
```

Then recompile:

```bash
mix deps.clean --all
mix deps.get
mix compile
MIX_ENV=test mix ecto.create
MIX_ENV=test mix ecto.migrate
mix test
```

## Alternative: Upgrade Elixir

If you want to use the latest Elixir (recommended):

```bash
# Using asdf (recommended)
asdf install elixir 1.17.0
asdf global elixir 1.17.0

# Or using apt (may have older version)
sudo apt-get install -y elixir
```

