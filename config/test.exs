import Config

config :phireflight, PhireFlight.Repo,
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  database: "phireflight_test#{System.get_env("MIX_TEST_PARTITION")}",
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: System.schedulers_online() * 2

config :phireflight, PhireFlightWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "phireflight_test_secret_key_base_must_be_at_least_64_bytes_long_for_security",
  server: false

config :phireflight, PhireFlight.Mailer, adapter: Swoosh.Adapters.Test

config :swoosh, :api_client, false

config :logger, level: :warning

config :phoenix, :plug_init_mode, :runtime

config :phoenix_live_view,
  enable_expensive_runtime_checks: true
