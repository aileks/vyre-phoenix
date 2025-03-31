defmodule Vyre.Messages do
  @moduledoc """
  The Messages context.
  """

  import Ecto.Query, warn: false
  alias Vyre.Repo

  alias Vyre.Messages.Message

  @doc """
  Returns the list of messages.

  ## Examples

      iex> list_messages()
      [%Message{}, ...]

  """
  def list_messages do
    Repo.all(Message)
  end

  @doc """
  Gets a single message.

  Raises `Ecto.NoResultsError` if the Message does not exist.

  ## Examples

      iex> get_message!(123)
      %Message{}

      iex> get_message!(456)
      ** (Ecto.NoResultsError)

  """
  def get_message!(id), do: Repo.get!(Message, id)

  @doc """
  Creates a message.

  ## Examples

      iex> create_message(%{field: value})
      {:ok, %Message{}}

      iex> create_message(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_message(attrs \\ %{}) do
    %Message{}
    |> Message.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a message.

  ## Examples

      iex> update_message(message, %{field: new_value})
      {:ok, %Message{}}

      iex> update_message(message, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_message(%Message{} = message, attrs) do
    message
    |> Message.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a message.

  ## Examples

      iex> delete_message(message)
      {:ok, %Message{}}

      iex> delete_message(message)
      {:error, %Ecto.Changeset{}}

  """
  def delete_message(%Message{} = message) do
    Repo.delete(message)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking message changes.

  ## Examples

      iex> change_message(message)
      %Ecto.Changeset{data: %Message{}}

  """
  def change_message(%Message{} = message, attrs \\ %{}) do
    Message.changeset(message, attrs)
  end

  alias Vyre.Messages.PrivateMessage

  @doc """
  Returns the list of private_messages.

  ## Examples

      iex> list_private_messages()
      [%PrivateMessage{}, ...]

  """
  def list_private_messages do
    Repo.all(PrivateMessage)
  end

  @doc """
  Gets a single private_message.

  Raises `Ecto.NoResultsError` if the Private message does not exist.

  ## Examples

      iex> get_private_message!(123)
      %PrivateMessage{}

      iex> get_private_message!(456)
      ** (Ecto.NoResultsError)

  """
  def get_private_message!(id), do: Repo.get!(PrivateMessage, id)

  @doc """
  Creates a private_message.

  ## Examples

      iex> create_private_message(%{field: value})
      {:ok, %PrivateMessage{}}

      iex> create_private_message(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_private_message(attrs \\ %{}) do
    %PrivateMessage{}
    |> PrivateMessage.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a private_message.

  ## Examples

      iex> update_private_message(private_message, %{field: new_value})
      {:ok, %PrivateMessage{}}

      iex> update_private_message(private_message, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_private_message(%PrivateMessage{} = private_message, attrs) do
    private_message
    |> PrivateMessage.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a private_message.

  ## Examples

      iex> delete_private_message(private_message)
      {:ok, %PrivateMessage{}}

      iex> delete_private_message(private_message)
      {:error, %Ecto.Changeset{}}

  """
  def delete_private_message(%PrivateMessage{} = private_message) do
    Repo.delete(private_message)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking private_message changes.

  ## Examples

      iex> change_private_message(private_message)
      %Ecto.Changeset{data: %PrivateMessage{}}

  """
  def change_private_message(%PrivateMessage{} = private_message, attrs \\ %{}) do
    PrivateMessage.changeset(private_message, attrs)
  end

  @doc """
  Returns the list of messages for a specific channel.
  """
  def list_channel_messages(channel_id) do
    Message
    |> where([m], m.channel_id == ^channel_id)
    |> order_by([m], asc: m.inserted_at)
    |> preload(:user)
    |> Repo.all()
  end

  @doc """
  Get message with preloaded user
  """
  def get_message_with_user(message_id) do
    Message
    |> Repo.get!(message_id)
    |> Repo.preload(:user)
  end

  def list_private_messages_between(user1_id, user2_id) do
    Repo.all(
      from pm in PrivateMessage,
        where:
          (pm.sender_id == ^user1_id and pm.receiver_id == ^user2_id) or
            (pm.sender_id == ^user2_id and pm.receiver_id == ^user1_id),
        order_by: [asc: pm.inserted_at],
        preload: [:sender, :receiver]
    )
  end

  def get_private_message_with_users(message_id) do
    Repo.get!(PrivateMessage, message_id)
    |> Repo.preload([:sender, :receiver])
  end

  def create_and_broadcast_private_message(attrs) do
    with {:ok, message} <- create_private_message(attrs) do
      message_with_users = get_private_message_with_users(message.id)

      Phoenix.PubSub.broadcast(
        Vyre.PubSub,
        conversation_topic(attrs.sender_id, attrs.receiver_id),
        {:new_private_message, message_with_users}
      )

      Phoenix.PubSub.broadcast(
        Vyre.PubSub,
        "user:#{attrs.receiver_id}:status",
        {:private_message_unread, attrs.sender_id}
      )

      {:ok, message_with_users}
    end
  end

  def mark_private_messages_as_read(receiver_id, sender_id) do
    {count, _} =
      from(pm in PrivateMessage,
        where: pm.sender_id == ^sender_id and pm.receiver_id == ^receiver_id and pm.read == false
      )
      |> Repo.update_all(set: [read: true, updated_at: DateTime.utc_now()])

    # Broadcast updated status if messages were marked as read
    if count > 0 do
      # Broadcast to the receiver's status topic that messages from this sender are now read
      Phoenix.PubSub.broadcast(
        Vyre.PubSub,
        "user:#{receiver_id}:status",
        {:private_message_read, sender_id}
      )
    end

    {:ok, count}
  end

  def user_private_message_topic(user_id, other_user_id) do
    "pm:#{user_id}:#{other_user_id}"
  end

  def conversation_topic(user1_id, user2_id) do
    ordered_ids = [user1_id, user2_id] |> Enum.sort() |> Enum.join(":")
    "pm:conversation:#{ordered_ids}"
  end
end
