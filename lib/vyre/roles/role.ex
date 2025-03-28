defmodule Vyre.Roles.Role do
  use Ecto.Schema
  import Ecto.Changeset

  @schema_prefix System.get_env("DB_SCHEMA")
  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "roles" do
    field :name, :string
    field :position, :integer
    field :permissions, :integer, default: 1
    field :color, :string, default: "#99AABB"
    field :hoist, :boolean, default: false
    field :mentionable, :boolean, default: false

    belongs_to :server, Vyre.Servers.Server, foreign_key: :server_id

    many_to_many :users, Vyre.Accounts.User,
      join_through: Vyre.Roles.UserRole,
      on_delete: :delete_all

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(role, attrs) do
    role
    |> cast(attrs, [:name, :color, :permissions, :position, :hoist, :mentionable])
    |> validate_required([:name, :color, :permissions, :position, :hoist, :mentionable])
  end
end
