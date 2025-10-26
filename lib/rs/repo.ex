defmodule Rs.Repo do
  use Ecto.Repo,
    otp_app: :rs,
    adapter: Ecto.Adapters.Postgres
end
