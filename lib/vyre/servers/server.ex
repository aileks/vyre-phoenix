defmodule Vyre.Servers.Server do
  use Ecto.Schema
  import Ecto.Changeset

  @schema_prefix System.get_env("DB_SCHEMA")
  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "servers" do
    field :name, :string
    field :description, :string
    field :invite, :string
    field :icon_url, :string

    has_many :channels, Vyre.Channels.Channel, on_delete: :delete_all
    has_many :roles, Vyre.Roles.Role, on_delete: :delete_all
    belongs_to :owner, Vyre.Accounts.User, foreign_key: :owner_id

    many_to_many :users, Vyre.Accounts.User,
      join_through: Vyre.Servers.ServerMember,
      on_delete: :delete_all

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(server, attrs) do
    server
    |> cast(attrs, [:name, :invite, :description, :icon_url, :owner_id])
    |> validate_required([:name, :invite, :description, :icon_url, :owner_id])
  end
end
