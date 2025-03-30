defmodule Vyre.Repo.Migrations.CreateMessages do
  use Ecto.Migration

  def change do
    create table(:messages, primary_key: false, prefix: System.get_env("DB_SCHEMA")) do
      add :id, :binary_id, primary_key: true
      add :content, :text, null: false
      add :edited, :boolean, default: false, null: false
      add :mentions_everyone, :boolean, default: false, null: false
      add :user_id, references(:users, on_delete: :delete_all, type: :binary_id), null: false

      add :channel_id, references(:channels, on_delete: :delete_all, type: :binary_id),
        null: false

      timestamps(type: :utc_datetime)
    end
  end
end
