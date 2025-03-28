defmodule Vyre.Repo.Migrations.CreateRoles do
  use Ecto.Migration

  def change do
    create table(:roles, primary_key: false, prefix: System.get_env("DB_SCHEMA")) do
      add :id, :binary_id, primary_key: true
      add :name, :string
      add :color, :string
      add :permissions, :integer
      add :position, :integer
      add :hoist, :boolean, default: false, null: false
      add :mentionable, :boolean, default: false, null: false
      add :server_id, references(:servers, on_delete: :delete_all, type: :binary_id)

      timestamps(type: :utc_datetime)
    end
  end
end
