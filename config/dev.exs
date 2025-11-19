import Config

config :phireflight, PhireFlight.Repo,
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  database: "phireflight_dev",
  stacktrace: true,
  show_sensitive_data_on_connection_error: true,
  pool_size: 10

config :phireflight, PhireFlightWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4000],
  check_origin: false,
  code_reloader: true,
  debug_errors: true,
  secret_key_base: "phireflight_dev_secret_key_base_must_be_at_least_64_bytes_long_for_security",
  watchers: [
    esbuild: {Esbuild, :install_and_run, [:phireflight, ~w(--sourcemap=inline --watch)]},
    tailwind: {Tailwind, :install_and_run, [:phireflight, ~w(--watch)]}
  ]

config :phireflight, PhireFlightWeb.Endpoint,
  live_reload: [
    patterns: [
      ~r"priv/static/(?!uploads/).*(js|css|png|jpeg|jpg|gif|svg)$",
      ~r"priv/gettext/.*(po)$",
      ~r"lib/phireflight_web/(controllers|live|components)/.*(ex|heex)$"
    ]
  ]

config :phireflight, dev_routes: true

config :logger, :console, format: "[$level] $message\n"

config :phoenix, :stacktrace_depth, 20

config :phoenix, :plug_init_mode, :runtime

config :swoosh, :api_client, false
