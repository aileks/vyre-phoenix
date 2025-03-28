defmodule Vyre.Repo.Migrations.CreateUserChannelStatuses do
  use Ecto.Migration

  def change do
    create table(:user_channel_statuses, primary_key: false, prefix: System.get_env("DB_SCHEMA")) do
      add :id, :binary_id, primary_key: true
      add :last_read_at, :utc_datetime
      add :mention_count, :integer, default: 0
      add :user_id, references(:users, on_delete: :delete_all, type: :binary_id), null: false

      add :channel_id, references(:channels, on_delete: :delete_all, type: :binary_id),
        null: false

      add :last_read_message_id, references(:messages, on_delete: :delete_all, type: :binary_id)

      timestamps(type: :utc_datetime)
    end

    create index(:user_channel_statuses, [:user_id])
    create index(:user_channel_statuses, [:channel_id])
    create index(:user_channel_statuses, [:last_read_message_id])
  end
end
