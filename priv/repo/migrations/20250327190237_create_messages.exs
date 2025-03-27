defmodule Vyre.Repo.Migrations.CreateMessages do
  use Ecto.Migration

  def change do
    create table(:messages, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :read, :boolean, default: false, null: false
      add :content, :text, null: false
      add :edited, :boolean, default: false, null: false
      add :mentions_everyone, :boolean, default: false, null: false
      add :user_id, references(:users, on_delete: :delete_all, type: :binary_id)
      add :channel_id, references(:channels, on_delete: :delete_all, type: :binary_id)

      timestamps(type: :utc_datetime)
    end
  end
end
