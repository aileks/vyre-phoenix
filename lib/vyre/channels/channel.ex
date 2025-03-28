defmodule Vyre.Channels.Channel do
  use Ecto.Schema
  import Ecto.Changeset

  @schema_prefix System.get_env("DB_SCHEMA")
  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "channels" do
    field :name, :string
    field :type, :string
    field :description, :string
    field :topic, :string

    belongs_to :server, Vyre.Servers.Server, foreign_key: :server_id
    has_many :messages, Vyre.Messages.Message, on_delete: :delete_all

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(channel, attrs) do
    channel
    |> cast(attrs, [:name, :topic, :description, :type])
    |> validate_required([:name, :topic, :description, :type])
  end
end
