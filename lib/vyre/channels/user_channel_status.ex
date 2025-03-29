defmodule Vyre.Channels.UserChannelStatus do
  use Ecto.Schema
  import Ecto.Changeset

  @schema_prefix System.get_env("DB_SCHEMA")
  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "user_channel_statuses" do
    field :last_read_at, :utc_datetime
    field :mention_count, :integer, default: 0
    field :user_id, :binary_id
    field :channel_id, :binary_id
    field :last_read_message_id, :binary_id

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(user_channel_status, attrs) do
    user_channel_status
    |> cast(attrs, [:user_id, :channel_id, :last_read_at, :mention_count, :last_read_message_id])
    |> validate_required([:user_id, :channel_id, :last_read_at, :mention_count])
  end
end
