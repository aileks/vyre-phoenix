defmodule Vyre.Repo do
  use Ecto.Repo,
    otp_app: :vyre,
    adapter: Ecto.Adapters.Postgres

  def init(_type, config) do
    if config[:adapter] == Ecto.Adapters.Postgres do
      db_schema = System.get_env("DB_SCHEMA") || "vyre"

      config =
        config
        |> Keyword.update(:parameters, [search_path: db_schema], fn params ->
          Keyword.put_new(params, :search_path, db_schema)
        end)
        |> Keyword.put(:migration_default_prefix, db_schema)

      {:ok, config}
    else
      {:ok, config}
    end
  end
end
