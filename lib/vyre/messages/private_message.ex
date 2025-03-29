defmodule Vyre.Messages.PrivateMessage do
  use Ecto.Schema
  import Ecto.Changeset

  @schema_prefix System.get_env("DB_SCHEMA")
  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "private_messages" do
    field :read, :boolean, default: false
    field :content, :string

    belongs_to :sender, Vyre.Accounts.User, foreign_key: :sender_id
    belongs_to :receiver, Vyre.Accounts.User, foreign_key: :receiver_id

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(private_message, attrs) do
    private_message
    |> cast(attrs, [:sender_id, :receiver_id, :content, :read])
    |> validate_required([:sender_id, :receiver_id, :content, :read])
  end
end
