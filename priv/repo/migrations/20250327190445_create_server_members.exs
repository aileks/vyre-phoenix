defmodule Vyre.Repo.Migrations.CreateServerMembers do
  use Ecto.Migration

  def change do
    create table(:server_members, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :nickname, :string
      add :server_id, references(:servers, on_delete: :delete_all, type: :binary_id)
      add :user_id, references(:users, on_delete: :delete_all, type: :binary_id)

      timestamps(type: :utc_datetime)
    end

    create index(:server_members, [:server_id])
    create index(:server_members, [:user_id])
  end
end
