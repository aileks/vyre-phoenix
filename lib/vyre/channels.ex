defmodule Vyre.Channels do
  @moduledoc """
  The Channels context.
  """

  import Ecto.Query, warn: false

  alias Vyre.Repo
  alias Vyre.Servers
  alias Vyre.Messages.Message
  alias Vyre.Channels.Channel
  alias Vyre.Channels.UserChannelStatus
  alias Vyre.Channels.StatusCache
  alias Vyre.Channels.StatusQueue

  @doc """
  Returns the list of channels.

  ## Examples

      iex> list_channels()
      [%Channel{}, ...]

  """
  def list_channels do
    Repo.all(Channel)
  end

  @doc """
  Gets a single channel.

  Raises `Ecto.NoResultsError` if the Channel does not exist.

  ## Examples

      iex> get_channel!(123)
      %Channel{}

      iex> get_channel!(456)
      ** (Ecto.NoResultsError)

  """
  def get_channel!(id), do: Repo.get!(Channel, id)

  @doc """
  Creates a channel.

  ## Examples

      iex> create_channel(%{field: value})
      {:ok, %Channel{}}

      iex> create_channel(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_channel(attrs \\ %{}) do
    %Channel{}
    |> Channel.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a channel.

  ## Examples

      iex> update_channel(channel, %{field: new_value})
      {:ok, %Channel{}}

      iex> update_channel(channel, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_channel(%Channel{} = channel, attrs) do
    channel
    |> Channel.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a channel.

  ## Examples

      iex> delete_channel(channel)
      {:ok, %Channel{}}

      iex> delete_channel(channel)
      {:error, %Ecto.Changeset{}}

  """
  def delete_channel(%Channel{} = channel) do
    Repo.delete(channel)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking channel changes.

  ## Examples

      iex> change_channel(channel)
      %Ecto.Changeset{data: %Channel{}}

  """
  def change_channel(%Channel{} = channel, attrs \\ %{}) do
    Channel.changeset(channel, attrs)
  end

  ## ----------------------------- ##
  ## USER CHANNEL STATUS FUNCTIONS ##
  ## ----------------------------- ##

  def mark_channel_as_read(user_id, channel_id, message_id \\ nil) do
    # Try getting the status from cache first
    last_status =
      case Vyre.Channels.StatusCache.get_status(user_id, channel_id) do
        {:ok, status} -> status
        {:error, :not_found} -> nil
      end

    # Decide if we should perform a full update or just cache
    should_update =
      cond do
        # No previous status - always update
        is_nil(last_status) ->
          true

        # Last update was more than 1 minute ago
        DateTime.diff(DateTime.utc_now(), last_status.updated_at) > 60 ->
          true

        !is_nil(message_id) && !is_nil(last_status.last_read_message_id) ->
          newer_message = Repo.get(Message, message_id)
          older_message = Repo.get(Message, last_status.last_read_message_id)

          if newer_message && older_message do
            time_diff = DateTime.diff(newer_message.inserted_at, older_message.inserted_at)
            time_diff > 300
          else
            true
          end

        # Otherwise, skip the full update
        true ->
          false
      end

    current_message_id = message_id || get_latest_message_id(channel_id)

    if should_update do
      params = %{
        user_id: user_id,
        channel_id: channel_id,
        last_read_at: DateTime.utc_now(),
        mention_count: 0,
        last_read_message_id: current_message_id
      }

      StatusQueue.mark_as_read(user_id, channel_id, current_message_id)
      StatusCache.update_status(user_id, channel_id, params)

      {:ok, :queued_for_update}
    else
      if last_status do
        cache_params = %{
          user_id: user_id,
          channel_id: channel_id,
          last_read_at: DateTime.utc_now(),
          mention_count: last_status.mention_count,
          last_read_message_id: current_message_id || last_status.last_read_message_id
        }

        # Update in cache only
        StatusCache.update_status(user_id, channel_id, cache_params)
        {:ok, :cache_updated}
      else
        # This is unusual but possible if cache was invalidated
        # Fall back to queue to ensure data integrity
        StatusQueue.mark_as_read(user_id, channel_id, current_message_id)
        {:ok, :fallback_queued}
      end
    end
  end

  def get_user_channel_status(user_id, channel_id) do
    Repo.one(
      from s in UserChannelStatus,
        where: s.user_id == ^user_id and s.channel_id == ^channel_id
    )
  end

  def channel_has_unread?(user_id, channel_id) do
    status = get_user_channel_status(user_id, channel_id)

    # If no status exists, channel has never been read
    if is_nil(status) do
      Repo.exists?(from m in Message, where: m.channel_id == ^channel_id)
    else
      # Check if there are messages newer than last read
      # Only check based on last_read_at if it exists
      case status.last_read_at do
        nil ->
          Repo.exists?(from m in Message, where: m.channel_id == ^channel_id)

        timestamp ->
          # Check for messages newer than the last read timestamp
          query =
            from m in Message,
              where: m.channel_id == ^channel_id and m.inserted_at > ^timestamp,
              limit: 1

          Repo.exists?(query)
      end
    end
  end

  def get_channel_mention_count(user_id, channel_id) do
    status = get_user_channel_status(user_id, channel_id)

    # If no status exists or no last read, count all mentions
    cond do
      is_nil(status) ->
        Repo.aggregate(
          from(m in Message,
            where: m.channel_id == ^channel_id and m.mentions_everyone == true
          ),
          :count
        )

      is_nil(status.last_read_at) ->
        Repo.aggregate(
          from(m in Message,
            where: m.channel_id == ^channel_id and m.mentions_everyone == true
          ),
          :count
        )

      true ->
        # Count mentions in messages newer than last read
        Repo.aggregate(
          from(m in Message,
            where:
              m.channel_id == ^channel_id and
                m.inserted_at > ^status.last_read_at and
                m.mentions_everyone == true
          ),
          :count
        )
    end
  end

  def broadcast_status_updates(channel_id, message) do
    # Get all members for this channel
    members = Servers.list_server_members()

    # For each member, update their status
    Enum.each(members, fn member ->
      # Skip the sender of the message
      unless member.user_id == message.user_id do
        # Calculate new status
        mention_count =
          if message.mentions_everyone do
            get_channel_mention_count(member.user_id, channel_id) + 1
          else
            get_channel_mention_count(member.user_id, channel_id)
          end

        status = %{
          has_unread: true,
          mention_count: mention_count
        }

        # Broadcast to this user's status topic
        Phoenix.PubSub.broadcast(
          Vyre.PubSub,
          "user:#{member.user_id}:status",
          {:channel_status_update, channel_id, status}
        )
      end
    end)
  end

  # Helper to get latest message ID in a channel
  defp get_latest_message_id(channel_id) do
    Repo.one(
      from m in Message,
        where: m.channel_id == ^channel_id,
        order_by: [desc: m.inserted_at],
        select: m.id,
        limit: 1
    )
  end
end
