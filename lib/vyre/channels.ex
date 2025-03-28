defmodule Vyre.Channels do
  @moduledoc """
  The Channels context.
  """

  import Ecto.Query, warn: false

  alias Vyre.Repo
  alias Vyre.Messages.Message
  alias Vyre.Channels.Channel
  alias Vyre.Channels.UserChannelStatus

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

  def mark_channel_as_read(user_id, channel_id) do
    latest_message =
      Repo.one(
        from m in Message,
          where: m.channel_id == ^channel_id,
          order_by: [desc: m.inserted_at],
          limit: 1
      )

    # Prepare the params based on whether there's a latest message
    params = %{
      user_id: user_id,
      channel_id: channel_id,
      last_read_at: DateTime.utc_now(),
      mention_count: 0
    }

    # Add the last_read_message_id only if we have a message
    params =
      if latest_message do
        Map.put(params, :last_read_message_id, latest_message.id)
      else
        params
      end

    # Update or create the user's channel status
    case get_user_channel_status(user_id, channel_id) do
      nil ->
        %UserChannelStatus{}
        |> UserChannelStatus.changeset(params)
        |> Repo.insert()

      status ->
        status
        |> UserChannelStatus.changeset(params)
        |> Repo.update()
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
end
