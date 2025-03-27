defmodule Vyre.Accounts.User do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "users" do
    field :email, :string
    field :username, :string
    field :display_name, :string
    field :avatar_url, :string, default: ""
    field :status, :string, default: "offline"
    field :password, :string, virtual: true, redact: true
    field :password_confirmation, :string, virtual: true, redact: true
    field :hashed_password, :string, redact: true
    field :current_password, :string, virtual: true, redact: true
    field :confirmed_at, :utc_datetime

    has_many :channel_messages, Vyre.Messages.Message, on_delete: :delete_all

    has_many :owned_servers, Vyre.Servers.Server,
      foreign_key: :owner_id,
      on_delete: :delete_all

    has_many :friendships, Vyre.Friends.Friend,
      foreign_key: :user_id,
      on_delete: :delete_all

    has_many :friend_requests, Vyre.Friends.Friend,
      foreign_key: :friend_id,
      on_delete: :delete_all

    has_many :sent_messages, Vyre.Messages.PrivateMessage,
      foreign_key: :sender_id,
      references: :id,
      on_delete: :delete_all

    has_many :recieved_messages, Vyre.Messages.PrivateMessage,
      foreign_key: :receiver_id,
      references: :id,
      on_delete: :delete_all

    many_to_many :roles, Vyre.Roles.Role,
      join_through: Vyre.Roles.UserRole,
      on_delete: :delete_all

    many_to_many :joined_servers, Vyre.Servers.Server,
      join_through: Vyre.Servers.ServerMember,
      on_delete: :delete_all

    timestamps(type: :utc_datetime)
  end

  @doc """
  A user changeset for registration.

  It is important to validate the length of both email and password.
  Otherwise databases may truncate the email without warnings, which
  could lead to unpredictable or insecure behaviour. Long passwords may
  also be very expensive to hash for certain algorithms.

  ## Options

    * `:hash_password` - Hashes the password so it can be stored securely
      in the database and ensures the password field is cleared to prevent
      leaks in the logs. If password hashing is not needed and clearing the
      password field is not desired (like when using this changeset for
      validations on a LiveView form), this option can be set to `false`.
      Defaults to `true`.

    * `:validate_email` - Validates the uniqueness of the email, in case
      you don't want to validate the uniqueness of the email (like when
      using this changeset for validations on a LiveView form before
      submitting the form), this option can be set to `false`.
      Defaults to `true`.
  """
  def registration_changeset(user, attrs, opts \\ []) do
    user
    |> cast(attrs, [:email, :username, :display_name, :status, :password, :password_confirmation])
    |> set_default_display_name()
    |> validate_email(opts)
    |> validate_username(opts)
    |> validate_password(opts)
  end

  defp set_default_display_name(changeset) do
    username = get_change(changeset, :username)
    display_name = get_change(changeset, :display_name)

    if is_nil(display_name) && username do
      put_change(changeset, :display_name, username)
    else
      changeset
    end
  end

  defp validate_email(changeset, opts) do
    changeset
    |> validate_required([:email])
    |> validate_format(:email, ~r/^[^\s]+@[^\s]+$/, message: "Must have the @ sign and no spaces")
    |> validate_length(:email, max: 160, message: "Email is too long")
    |> maybe_validate_unique_email(opts)
  end

  defp validate_username(changeset, opts) do
    changeset
    |> validate_format(:username, ~r/^[a-z0-9_-]+$/i,
      message: "Only letters, numbers, underscores and dashes"
    )
    |> validate_length(:username, min: 3, max: 30, message: "Must be between 3 and 30 characters")
    |> maybe_validate_unique_username(opts)
  end

  defp validate_password(changeset, opts) do
    changeset
    |> validate_required([:password])
    |> validate_length(:password, min: 12, max: 72)
    |> validate_format(:password, ~r/[a-z]/,
      message: "Must have at least one lower case character"
    )
    |> validate_format(:password, ~r/[A-Z]/,
      message: "Must have at least one upper case character"
    )
    |> validate_format(:password, ~r/[0-9]/, message: "Must contain at least one number")
    |> validate_format(:password, ~r/[!?@#$%^&*_]/,
      message: "Must contain at least one special character"
    )
    |> maybe_hash_password(opts)
  end

  defp maybe_hash_password(changeset, opts) do
    hash_password? = Keyword.get(opts, :hash_password, true)
    password = get_change(changeset, :password)

    if hash_password? && password && changeset.valid? do
      changeset
      # If using Bcrypt, then further validate it is at most 72 bytes long
      |> validate_length(:password, max: 72, count: :bytes)
      # Hashing could be done with `Ecto.Changeset.prepare_changes/2`, but that
      # would keep the database transaction open longer and hurt performance.
      |> put_change(:hashed_password, Bcrypt.hash_pwd_salt(password))
      |> delete_change(:password)
      |> delete_change(:password_confirmation)
    else
      changeset
    end
  end

  defp maybe_validate_unique_email(changeset, opts) do
    if Keyword.get(opts, :validate_email, true) do
      changeset
      |> unsafe_validate_unique(:email, Vyre.Repo)
      |> unique_constraint(:email)
    else
      changeset
    end
  end

  defp maybe_validate_unique_username(changeset, opts) do
    if Keyword.get(opts, :validate_username, true) do
      changeset
      |> unsafe_validate_unique(:username, Vyre.Repo)
      |> unique_constraint(:username)
    else
      changeset
    end
  end

  @doc """
  A user changeset for changing the email.

  It requires the email to change otherwise an error is added.
  """
  def email_changeset(user, attrs, opts \\ []) do
    user
    |> cast(attrs, [:email])
    |> validate_email(opts)
    |> case do
      %{changes: %{email: _}} = changeset -> changeset
      %{} = changeset -> add_error(changeset, :email, "Did not change")
    end
  end

  @doc """
  A user changeset for changing the password.

  ## Options

    * `:hash_password` - Hashes the password so it can be stored securely
      in the database and ensures the password field is cleared to prevent
      leaks in the logs. If password hashing is not needed and clearing the
      password field is not desired (like when using this changeset for
      validations on a LiveView form), this option can be set to `false`.
      Defaults to `true`.
  """
  def password_changeset(user, attrs, opts \\ []) do
    user
    |> cast(attrs, [:password])
    |> validate_confirmation(:password, message: "Does not match password")
    |> validate_password(opts)
  end

  @doc """
  Confirms the account by setting `confirmed_at`.
  """
  def confirm_changeset(user) do
    now = DateTime.utc_now() |> DateTime.truncate(:second)
    change(user, confirmed_at: now)
  end

  @doc """
  Verifies the password.

  If there is no user or the user doesn't have a password, we call
  `Bcrypt.no_user_verify/0` to avoid timing attacks.
  """
  def valid_password?(%Vyre.Accounts.User{hashed_password: hashed_password}, password)
      when is_binary(hashed_password) and byte_size(password) > 0 do
    Bcrypt.verify_pass(password, hashed_password)
  end

  def valid_password?(_, _) do
    Bcrypt.no_user_verify()
    false
  end

  @doc """
  Validates the current password otherwise adds an error to the changeset.
  """
  def validate_current_password(changeset, password) do
    changeset = cast(changeset, %{current_password: password}, [:current_password])

    if valid_password?(changeset.data, password) do
      changeset
    else
      add_error(changeset, :current_password, "is not valid")
    end
  end
end
