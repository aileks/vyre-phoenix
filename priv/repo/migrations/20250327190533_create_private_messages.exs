defmodule Vyre.Repo.Migrations.CreatePrivateMessages do
  use Ecto.Migration

  def change do
    create table(:private_messages, primary_key: false, prefix: System.get_env("DB_SCHEMA")) do
      add :id, :binary_id, primary_key: true
      add :content, :text
      add :read, :boolean, default: false, null: false
      add :sender_id, references(:users, on_delete: :delete_all, type: :binary_id)
      add :receiver_id, references(:users, on_delete: :delete_all, type: :binary_id)

      timestamps(type: :utc_datetime)
    end

    create index(:private_messages, [:sender_id])
    create index(:private_messages, [:receiver_id])
  end
end
