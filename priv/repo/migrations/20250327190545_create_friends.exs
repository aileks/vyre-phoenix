defmodule Vyre.Repo.Migrations.CreateFriends do
  use Ecto.Migration

  def change do
    create table(:friends, primary_key: false, prefix: System.get_env("DB_SCHEMA")) do
      add :id, :binary_id, primary_key: true
      add :status, :string, default: "pending"
      add :user_id, references(:users, on_delete: :delete_all, type: :binary_id)
      add :friend_id, references(:users, on_delete: :delete_all, type: :binary_id)

      timestamps(type: :utc_datetime)
    end

    create index(:friends, [:user_id])
    create index(:friends, [:friend_id])
  end
end
