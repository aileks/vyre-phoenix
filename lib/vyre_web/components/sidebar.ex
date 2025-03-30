defmodule VyreWeb.Components.Sidebar do
  use VyreWeb, :live_component

  import Ecto.Query
  alias Vyre.Repo
  alias Vyre.Channels
  alias Vyre.Channels.UserChannelStatus

  @impl true
  def mount(socket) do
    {:ok, socket}
  end

  @impl true
  def update(assigns, socket) do
    socket = assign(socket, assigns)

    if assigns[:current_user] do
      current_user = assigns.current_user

      user_with_data =
        Repo.preload(current_user, [
          :sent_messages,
          :received_messages,
          joined_servers: [:channels],
          owned_servers: [:channels]
        ])

      private_messages = get_user_private_messages(user_with_data)
      servers = get_user_servers_with_status(user_with_data)

      socket =
        assign(socket,
          pm_expanded: true,
          all_servers_expanded: true,
          private_messages: private_messages,
          servers: servers
        )

      {:ok, socket}
    else
      # Handle case when no current_user is provided
      {:ok,
       assign(socket,
         pm_expanded: true,
         all_servers_expanded: true,
         private_messages: [],
         servers: []
       )}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="bg-midnight-900 flex h-full w-64 flex-col border-r border-gray-700">
      <!-- Header with user info -->
      <div class="border-b border-gray-700 p-4">
        <div class="flex items-center justify-between">
          <div class="flex items-center">
            <div class="relative mr-3">
              <img src={@current_user.avatar_url} class="user-avatar h-10 w-10" alt="User avatar" />

              <div class={[
                "border-midnight-900 status-indicator-#{@current_user.status}",
                "absolute -right-0.5 -bottom-0.5 h-3 w-3 rounded-full border-2"
              ]}>
              </div>
            </div>

            <div>
              <div class="text-cybertext-200 font-mono">
                {@current_user.display_name}
              </div>

              <div class="text-cybertext-500 text-xs">Connected</div>
            </div>
          </div>
          
    <!-- Settings button -->
          <div phx-click="open_settings" phx-target={@myself} class="p-2" aria-label="Open settings">
            <Heroicons.icon
              name="cog-6-tooth"
              class="text-cybertext-400 hover:text-cybertext-50 justify-center duration-200 ease-in-out transition-all cursor-pointer h-5 w-5"
            />
          </div>
        </div>
      </div>
      
    <!-- Navigation -->
      <div class="flex-1 overflow-y-auto p-2">
        <div class="mb-4 space-y-1">
          <.link
            navigate={~p"/app/friends"}
            class={[
              "flex items-center rounded-xs px-3 py-2",
              @current_path == "/app/friends" && "bg-primary-900 text-primary-300",
              @current_path != "/app/friends" && "text-cybertext-400 hover:bg-midnight-700"
            ]}
          >
            <Heroicons.icon name="user-group" class="mr-3 h-5 w-5" /> Friends
          </.link>
        </div>
        
    <!-- Private Messages -->
        <div class="mb-4">
          <div
            class="flex cursor-pointer items-center justify-between px-1 text-sm"
            phx-click="toggle_pm"
            phx-target={@myself}
          >
            <span class="text-cybertext-500 font-mono uppercase">
              Private Messages
            </span>

            <Heroicons.icon
              name={if @pm_expanded, do: "chevron-down", else: "chevron-right"}
              class="text-cybertext-500 h-4 w-4"
            />
          </div>

          <%= if @pm_expanded do %>
            <div class="mt-1 space-y-1">
              <%= for pm <- @private_messages do %>
                <.link
                  navigate={~p"/app/channels/#{pm.user_id}"}
                  class={[
                    "flex items-center rounded-xs px-3 py-2",
                    @current_path == "/app/channels/#{pm.id}" && "bg-primary-900 text-primary-300",
                    @current_path != "/app/channels/#{pm.id}" &&
                      "text-cybertext-400 hover:bg-midnight-700"
                  ]}
                >
                  <div class="relative mr-2">
                    <img
                      src={pm.avatar_url || "/images/default-avatar.png"}
                      alt={pm.username}
                      class="user-avatar h-8 w-8"
                    />

                    <%= case pm.status do %>
                      <% "online" -> %>
                        <div class="status-indicator-online absolute -right-0.5 -bottom-0.5"></div>
                      <% "away" -> %>
                        <div class="status-indicator-away absolute -right-0.5 -bottom-0.5"></div>
                      <% "busy" -> %>
                        <div class="status-indicator-busy absolute -right-0.5 -bottom-0.5"></div>
                      <% _ -> %>
                        <div class="status-indicator-offline absolute -right-0.5 -bottom-0.5"></div>
                    <% end %>
                  </div>

                  <span class="flex-grow truncate">{pm.username}</span>

                  <%= if pm.unread do %>
                    <div class="bg-primary-400 ml-auto h-2 w-2 rounded-full"></div>
                  <% end %>
                </.link>
              <% end %>
            </div>
          <% end %>
        </div>
        
    <!-- Servers -->
        <div>
          <div
            class="flex cursor-pointer items-center justify-between px-1 text-sm"
            phx-click="toggle_servers"
            phx-target={@myself}
          >
            <span class="text-cybertext-500 font-mono uppercase">
              Servers
            </span>

            <Heroicons.icon
              name={if @all_servers_expanded, do: "chevron-down", else: "chevron-right"}
              class="text-cybertext-500 h-4 w-4"
            />
          </div>

          <%= if @all_servers_expanded do %>
            <div class="mt-1 space-y-3">
              <%= for server <- @servers do %>
                <div
                  class="px-3 py-1 text-sm"
                  phx-click="toggle_server"
                  phx-value-id={server.id}
                  phx-target={@myself}
                >
                  <div class="flex items-center justify-between font-mono text-sm">
                    {server.name}
                  </div>

                  <div class="mt-1 ml-2 space-y-1">
                    <%= for channel <- server.channels do %>
                      <.link
                        navigate={~p"/app/channels/#{channel.id}"}
                        class={[
                          "flex items-center rounded-xs px-3 py-1",
                          @current_path == "/app/channels/#{server.id}-#{channel.name}" &&
                            "bg-primary-900 text-primary-300",
                          @current_path != "/app/channels/#{server.id}-#{channel.name}" &&
                            "text-cybertext-400 hover:bg-midnight-700"
                        ]}
                      >
                        <span class="text-cybertext-500 mr-1">#</span>
                        <span>{channel.name}</span>

                        <%= if Map.get(channel, :computed) && channel.computed.has_unread do %>
                          <div class="bg-warning-300 ml-2 h-2 w-2 rounded-full"></div>
                        <% end %>

                        <%= if Map.get(channel, :computed) && channel.computed.mention_count > 0 do %>
                          <div class="bg-error-500 text-error-200 font-semibold ml-auto rounded-full px-[4px] text-center text-xs">
                            {channel.computed.mention_count}
                          </div>
                        <% end %>
                      </.link>
                    <% end %>
                  </div>
                </div>
              <% end %>
            </div>
          <% end %>
        </div>
      </div>

      <div class="bg-midnight-900 border-t border-gray-700 p-3">
        <!-- Commands button -->
        <button
          phx-click="open_commands"
          phx-target={@myself}
          class="bg-midnight-600 hover:bg-midnight-500 text-cybertext-400 hover:text-cybertext-200 flex w-full items-center rounded-xs px-3 py-2 duration-200 ease-in-out cursor-pointer"
          aria-label="Open commands"
        >
          <span class="text-primary-500 mr-2">/</span>
          Commands
          <kbd class="bg-midnight-800 text-cybertext-500 ml-auto rounded-xs px-1.5 py-0.5 text-xs">
            Ctrl+K
          </kbd>
        </button>
      </div>
    </div>
    """
  end

  def get_channels_with_status_for_user(user) do
    # Extract channels from preloaded user data
    channels =
      (user.joined_servers ++ user.owned_servers)
      |> Enum.flat_map(fn server -> server.channels end)
      |> Enum.uniq_by(fn channel -> channel.id end)

    # Get status for all channels in one batch from cache
    user_id = user.id
    channel_ids = Enum.map(channels, & &1.id)
    statuses = batch_get_channel_statuses(user_id, channel_ids)

    # Combine the data
    Enum.map(channels, fn channel ->
      status = Map.get(statuses, channel.id, %{has_unread: false, mention_count: 0})
      Map.put(channel, :computed, status)
    end)
  end

  def batch_get_channel_statuses(user_id, channel_ids) do
    # Try to get all statuses from cache first
    cached_results =
      Enum.map(channel_ids, fn channel_id ->
        key = "#{user_id}:#{channel_id}"

        case :ets.lookup(:channel_status_cache, key) do
          [{^key, status}] -> {channel_id, status}
          [] -> nil
        end
      end)
      |> Enum.reject(&is_nil/1)
      |> Map.new(fn {channel_id, status} ->
        {channel_id,
         %{
           has_unread: Channels.channel_has_unread?(user_id, channel_id, status),
           mention_count: status.mention_count || 0
         }}
      end)

    # For any missing channels, batch fetch from DB
    missing_channel_ids =
      Enum.reject(channel_ids, &Map.has_key?(cached_results, &1))

    missing_statuses =
      if Enum.empty?(missing_channel_ids) do
        %{}
      else
        Repo.all(
          from(ucs in UserChannelStatus,
            where: ucs.user_id == ^user_id and ucs.channel_id in ^missing_channel_ids,
            select: {ucs.channel_id, ucs}
          )
        )
        |> Map.new(fn {channel_id, status} ->
          # Cache the result
          :ets.insert(:channel_status_cache, {"#{user_id}:#{channel_id}", status})

          # Return the computed status values
          {channel_id,
           %{
             has_unread: Channels.channel_has_unread?(user_id, channel_id),
             mention_count: status.mention_count || 0
           }}
        end)
      end

    Map.merge(cached_results, missing_statuses)
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
      other_user = Repo.get(Vyre.Accounts.User, other_user_id)

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
    owned = user.owned_servers || []
    joined = user.joined_servers || []

    user_id = user.id

    servers =
      (owned ++ joined)
      |> Enum.uniq_by(fn server -> server.id end)
      |> Enum.sort_by(fn server -> server.name end)
      |> Repo.preload(:channels)

    Enum.map(servers, fn server ->
      channels =
        Enum.map(server.channels, fn channel ->
          # Efficiently check status using cache when possible
          has_unread = get_cached_unread_status(user_id, channel.id)
          mention_count = get_cached_mention_count(user_id, channel.id)

          # Add computed properties to each channel
          Map.put(channel, :computed, %{
            has_unread: has_unread,
            mention_count: mention_count
          })
        end)

      %{server | channels: channels}
    end)
  end

  defp get_cached_unread_status(user_id, channel_id) do
    # Try to get from cache first
    try do
      case :ets.lookup(:channel_status_cache, "#{user_id}:#{channel_id}:unread") do
        [{_, value}] ->
          value

        [] ->
          # Cache miss - get from Channels context
          result = Channels.channel_has_unread?(user_id, channel_id)
          # Try to cache the result (might fail if table doesn't exist)
          try do
            :ets.insert(:channel_status_cache, {"#{user_id}:#{channel_id}:unread", result})
          rescue
            _ -> :ok
          end

          result
      end
    rescue
      _ ->
        # Fall back to direct calculation if cache isn't available
        Channels.channel_has_unread?(user_id, channel_id)
    end
  end

  defp get_cached_mention_count(user_id, channel_id) do
    # Try to get from cache first
    try do
      case :ets.lookup(:channel_status_cache, "#{user_id}:#{channel_id}:mentions") do
        [{_, count}] ->
          count

        [] ->
          # Cache miss - get from Channels context
          count = Channels.get_channel_mention_count(user_id, channel_id)
          # Try to cache the result (might fail if table doesn't exist)
          try do
            :ets.insert(:channel_status_cache, {"#{user_id}:#{channel_id}:mentions", count})
          rescue
            _ -> :ok
          end

          count
      end
    rescue
      _ ->
        # Fall back to direct calculation if cache isn't available
        Channels.get_channel_mention_count(user_id, channel_id)
    end
  end

  # Event handlers
  @impl true
  def handle_event("toggle_pm", _, socket) do
    {:noreply, assign(socket, pm_expanded: !socket.assigns.pm_expanded)}
  end

  @impl true
  def handle_event("toggle_servers", _, socket) do
    {:noreply, assign(socket, all_servers_expanded: !socket.assigns.all_servers_expanded)}
  end

  @impl true
  def handle_event("open_commands", _, socket) do
    send(self(), {:open_commands})
    {:noreply, socket}
  end

  @impl true
  def handle_event("open_settings", _, socket) do
    send(self(), {:open_settings})
    {:noreply, socket}
  end

  @impl true
  def handle_info({:invalidate_cache, key}, socket) do
    :ets.delete(:channel_status_cache, key)
    {:noreply, socket}
  end
end
