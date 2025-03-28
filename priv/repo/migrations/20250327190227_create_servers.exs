defmodule Vyre.Repo.Migrations.CreateServers do
  use Ecto.Migration

  def change do
    create table(:servers, primary_key: false, prefix: System.get_env("DB_SCHEMA")) do
      add :id, :binary_id, primary_key: true
      add :name, :string
      add :invite, :string
      add :description, :text
      add :icon_url, :string
      add :owner_id, references(:users, on_delete: :delete_all, type: :binary_id)

      timestamps(type: :utc_datetime)
    end
  end
end
