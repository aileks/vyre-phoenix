defmodule Vyre.Repo.Migrations.UpdatePrivateMessagesTable do
  use Ecto.Migration

  def change do
    alter table(:private_messages) do
      add :edited, :boolean, default: false
    end
  end
end
