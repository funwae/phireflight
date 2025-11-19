import Config

config :phireflight, PhireFlightWeb.Endpoint, cache_static_manifest: "priv/static/cache_manifest.json"

config :swoosh, api_client: Finch, finch_name: PhireFlight.Finch

config :logger, level: :info
