defmodule Vyre.Roles.UserRole do
  use Ecto.Schema
  import Ecto.Changeset

  @schema_prefix System.get_env("DB_SCHEMA")
  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "user_roles" do
    belongs_to :user, Vyre.Accounts.User, foreign_key: :user_id
    belongs_to :role, Vyre.Servers.Server, foreign_key: :role_id

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(user_role, attrs) do
    user_role
    |> cast(attrs, [:user_id, :role_id])
    |> validate_required([:user_id, :role_id])
  end
end
