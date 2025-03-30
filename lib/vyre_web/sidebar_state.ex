defmodule VyreWeb.SidebarState do
  use Agent

  @registry_name :sidebar_state

  def start_link(_) do
    Agent.start_link(
      fn ->
        %{
          pm_expanded: true,
          all_servers_expanded: true,
          private_messages: [],
          servers: []
        }
      end,
      name: @registry_name
    )
  end

  def get_state do
    Agent.get(@registry_name, & &1)
  end

  def load_for_user(user) do
    try do
      user_with_data =
        Vyre.Repo.preload(
          user,
          [
            :sent_messages,
            :received_messages,
            joined_servers: [channels: [], owner: []],
            owned_servers: [channels: [], owner: []]
          ]
        )

      private_messages = get_user_private_messages(user_with_data)

      servers = get_user_servers_with_status(user_with_data)

      # Update the state with the loaded data
      update_state(fn _ ->
        %{
          pm_expanded: true,
          all_servers_expanded: true,
          private_messages: private_messages,
          servers: servers
        }
      end)

      # Return the new state for immediate use
      {:ok, get_state()}
    rescue
      e ->
        {:error, e}
    end
  end

  def update_state(update_fn) when is_function(update_fn, 1) do
    Agent.update(@registry_name, update_fn)
  end

  def update_channel_status(channel_id, status) do
    update_state(fn state ->
      updated_servers =
        Enum.map(state.servers, fn server ->
          updated_channels =
            Enum.map(server.channels, fn channel ->
              if channel.id == channel_id do
                current_computed = channel.computed || %{}
                updated_computed = Map.merge(current_computed, status)
                %{channel | computed: updated_computed}
              else
                channel
              end
            end)

          %{server | channels: updated_channels}
        end)

      %{state | servers: updated_servers}
    end)
  end

  defp get_user_private_messages(user) do
    sent = user.sent_messages || []
    received = user.received_messages || []

    (sent ++ received)
    |> Enum.sort_by(fn msg -> msg.inserted_at end, {:desc, DateTime})
    |> Enum.uniq_by(fn msg ->
      users = [msg.sender_id, msg.receiver_id] |> Enum.sort()
      "#{users}"
    end)
    |> Enum.map(fn msg ->
      # Determine if the message is unread (for received messages where the user is the receiver)
      unread = msg.receiver_id == user.id && !msg.read

      # Get the other user's information
      other_user_id = if msg.sender_id == user.id, do: msg.receiver_id, else: msg.sender_id
      other_user = Vyre.Repo.get(Vyre.Accounts.User, other_user_id)

      # Add status and username to each private message conversation
      %{
        id: msg.id,
        user_id: other_user.id,
        avatar_url: other_user.avatar_url,
        unread: unread,
        username: other_user.username,
        status: other_user.status
      }
    end)
  end

  defp get_user_servers_with_status(user) do
    try do
      owned = user.owned_servers || []
      joined = user.joined_servers || []

      user_id = user.id

      servers =
        (owned ++ joined)
        |> Enum.uniq_by(fn server -> server.id end)
        |> Enum.sort_by(fn server -> server.name end)
        |> Vyre.Repo.preload(:channels)

      Enum.map(servers, fn server ->
        channels =
          Enum.map(server.channels || [], fn channel ->
            # Safely get status with error handling
            has_unread =
              try do
                get_cached_unread_status(user_id, channel.id)
              rescue
                _ -> false
              end

            mention_count =
              try do
                get_cached_mention_count(user_id, channel.id)
              rescue
                _ -> 0
              end

            Map.put(channel, :computed, %{
              has_unread: has_unread,
              mention_count: mention_count
            })
          end)

        %{server | channels: channels}
      end)
    rescue
      _error ->
        []
    end
  end

  defp get_cached_unread_status(user_id, channel_id) do
    key = Vyre.Channels.StatusCache.make_key(user_id, channel_id)

    case :ets.lookup(:channel_status_cache, key) do
      [{^key, _status}] ->
        # If we have a cached status, compute unread state
        Vyre.Channels.channel_has_unread?(user_id, channel_id)

      [] ->
        # Cache miss - get directly from Channels context
        Vyre.Channels.channel_has_unread?(user_id, channel_id)
    end
  end

  defp get_cached_mention_count(user_id, channel_id) do
    key = Vyre.Channels.StatusCache.make_key(user_id, channel_id)

    case :ets.lookup(:channel_status_cache, key) do
      [{^key, status}] ->
        status.mention_count || 0

      [] ->
        Vyre.Channels.get_channel_mention_count(user_id, channel_id)
    end
  end
end
