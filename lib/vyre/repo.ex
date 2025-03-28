defmodule Vyre.Repo do
  use Ecto.Repo,
    otp_app: :vyre,
    adapter: Ecto.Adapters.Postgres
end
