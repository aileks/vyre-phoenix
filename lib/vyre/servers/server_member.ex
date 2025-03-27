defmodule Vyre.Servers.ServerMember do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "server_members" do
    field :nickname, :string

    belongs_to :user, Vyre.Accounts.User, foreign_key: :user_id
    belongs_to :server, Vyre.Servers.Server, foreign_key: :server_id

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(server_member, attrs) do
    server_member
    |> cast(attrs, [:nickname])
    |> validate_required([:nickname])
  end
end
