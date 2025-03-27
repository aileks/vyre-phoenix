defmodule Vyre.Friends.Friend do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "friends" do
    field :status, :string, default: "pending"

    belongs_to :user, Vyre.Accounts.User, foreign_key: :user_id
    belongs_to :friend, Vyre.Accounts.User, foreign_key: :friend_id

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(friend, attrs) do
    friend
    |> cast(attrs, [])
    |> validate_required([])
  end
end
