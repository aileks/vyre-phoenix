defmodule Vyre.Repo.Migrations.CreateUsersAuthTables do
  use Ecto.Migration

  def change do
    execute "CREATE EXTENSION IF NOT EXISTS citext WITH SCHEMA #{System.get_env("DB_SCHEMA")}", ""

    create table(:users, primary_key: false, prefix: System.get_env("DB_SCHEMA")) do
      add :id, :binary_id, primary_key: true
      add :email, :"#{System.get_env("DB_SCHEMA")}.citext", null: false
      add :username, :string, null: false
      add :display_name, :string, null: false
      add :avatar_url, :string
      add :status, :string, default: "offline", null: false
      add :hashed_password, :string, null: false
      add :confirmed_at, :utc_datetime

      timestamps(type: :utc_datetime)
    end

    create unique_index(:users, [:email])

    create table(:users_tokens, primary_key: false, prefix: System.get_env("DB_SCHEMA")) do
      add :id, :binary_id, primary_key: true
      add :user_id, references(:users, on_delete: :delete_all, type: :binary_id), null: false
      add :token, :binary, null: false
      add :context, :string, null: false
      add :sent_to, :string

      timestamps(type: :utc_datetime, updated_at: false)
    end

    create index(:users_tokens, [:user_id])
    create unique_index(:users_tokens, [:context, :token])
  end
end
