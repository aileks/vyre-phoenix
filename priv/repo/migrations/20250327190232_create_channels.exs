defmodule Vyre.Repo.Migrations.CreateChannels do
  use Ecto.Migration

  def change do
    create table(:channels, primary_key: false, prefix: System.get_env("DB_SCHEMA")) do
      add :id, :binary_id, primary_key: true
      add :name, :string
      add :topic, :text
      add :description, :text
      add :type, :string
      add :server_id, references(:servers, on_delete: :delete_all, type: :binary_id)

      timestamps(type: :utc_datetime)
    end
  end
end
