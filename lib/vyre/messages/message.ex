defmodule Vyre.Messages.Message do
  use Ecto.Schema
  import Ecto.Changeset

  @schema_prefix System.get_env("DB_SCHEMA")
  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "messages" do
    field :content, :string
    field :read, :boolean, default: false
    field :edited, :boolean, default: false
    field :mentions_everyone, :boolean, default: false

    belongs_to :user, Vyre.Accounts.User, foreign_key: :user_id
    belongs_to :channel, Vyre.Channels.Channel, foreign_key: :channel_id

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(message, attrs) do
    message
    |> cast(attrs, [:content, :edited, :mentions_everyone])
    |> validate_required([:content, :edited, :mentions_everyone])
  end
end
