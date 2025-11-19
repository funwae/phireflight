defmodule PhireFlight.Repo do
  use Ecto.Repo,
    otp_app: :phireflight,
    adapter: Ecto.Adapters.Postgres
end
