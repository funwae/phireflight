import Config

config :phireflight,
  ecto_repos: [PhireFlight.Repo],
  generators: [timestamp_type: :utc_datetime]

config :phireflight, PhireFlightWeb.Endpoint,
  url: [host: "localhost"],
  adapter: Bandit.PhoenixAdapter,
  render_errors: [
    formats: [html: PhireFlightWeb.ErrorHTML, json: PhireFlightWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: PhireFlight.PubSub,
  live_view: [signing_salt: "phireflight_secret"]

config :phireflight, PhireFlight.Mailer, adapter: Swoosh.Adapters.Local

config :esbuild,
  version: "0.17.11",
  phireflight: [
    args:
      ~w(js/app.js --bundle --target=es2017 --outdir=../priv/static/assets --external:/fonts/* --external:/images/*),
    cd: Path.expand("../assets", __DIR__),
    env: %{"NODE_PATH" => Path.expand("../deps", __DIR__)}
  ]

config :tailwind,
  version: "3.4.3",
  phireflight: [
    args: ~w(
      --config=tailwind.config.js
      --input=css/app.css
      --output=../priv/static/assets/app.css
    ),
    cd: Path.expand("../assets", __DIR__)
  ]

config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

config :phoenix, :json_library, Jason

import_config "#{config_env()}.exs"
