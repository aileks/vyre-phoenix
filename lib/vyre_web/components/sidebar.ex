defmodule VyreWeb.Components.Sidebar do
  use VyreWeb, :live_component

  def render(assigns) do
    ~H"""
    <div class="bg-midnight-900 flex h-full w-64 flex-col border-r border-gray-700">
      <!-- Header with user info -->
      <div class="border-b border-gray-700 p-4">
        <div class="flex items-center justify-between">
          <div class="flex items-center">
            <div class="relative mr-3">
              <div class="bg-primary-600 flex h-10 w-10 items-center justify-center rounded-full text-sm">
                {@current_user.avatar_url}
              </div>

              <div class="border-midnight-900 status-indicator-away absolute -right-0.5 -bottom-0.5 h-3 w-3 rounded-full border-2">
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
            class="flex cursor-pointer items-center justify-between px-3 py-1 text-sm"
            phx-click="toggle_pm"
            phx-target={@myself}
          >
            <span class="text-cybertext-500 font-mono text-xs uppercase">
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
                  href="#"
                  class={[
                    "flex items-center rounded-xs px-3 py-2",
                    @current_path == "/app/channels/#{pm.id}" && "bg-primary-900 text-primary-300",
                    @current_path != "/app/channels/#{pm.id}" &&
                      "text-cybertext-400 hover:bg-midnight-700"
                  ]}
                >
                  <div class="relative mr-2">
                    <div class="bg-electric-800 flex h-6 w-6 items-center justify-center rounded-xs text-xs">
                      {String.first(pm.username) |> String.upcase()}
                    </div>
                    <div class={"border-midnight-800 absolute -right-0.5 -bottom-0.5 h-2 w-2 rounded-full border-2 status-indicator-#{pm.status}"}>
                    </div>
                  </div>

                  <span>{pm.username}</span>
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
            class="flex cursor-pointer items-center justify-between px-3 py-1 text-sm"
            phx-click="toggle_servers"
            phx-target={@myself}
          >
            <span class="text-cybertext-500 font-mono text-xs uppercase">
              Servers
            </span>
            <Heroicons.icon
              name={if @servers_expanded, do: "chevron-down", else: "chevron-right"}
              class="text-cybertext-500 h-4 w-4"
            />
          </div>

          <%= if @servers_expanded do %>
            <div class="mt-1 space-y-3">
              <%= for server <- @servers do %>
                <div>
                  <div class="flex items-center px-3 py-1">
                    <span class="text- font-mono text-sm">{server.name}</span>
                  </div>
                  <div class="mt-1 ml-2 space-y-1">
                    <%= for channel <- server.channels do %>
                      <.link
                        href="#"
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
                          <div class="bg-primary-400 ml-auto h-2 w-2 rounded-full"></div>
                        <% end %>

                        <%= if Map.get(channel, :computed) && channel.computed.mention_count > 0 do %>
                          <div class="bg-error-600 text-error-200 ml-auto rounded-xs px-1.5 text-xs">
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
          <span>Commands</span>
          <kbd class="bg-midnight-800 text-cybertext-500 ml-auto rounded-xs px-1.5 py-0.5 text-xs">
            Ctrl+K
          </kbd>
        </button>
      </div>
    </div>
    """
  end

  def mount(socket) do
    {:ok, socket}
  end

  def update(assigns, socket) do
    socket = assign(socket, assigns)

    if assigns[:current_user] do
      current_user = assigns.current_user

      user_with_data =
        Vyre.Repo.preload(current_user, [
          :sent_messages,
          :received_messages,
          joined_servers: [:channels],
          owned_servers: [:channels]
        ])

      private_messages = get_user_private_messages(user_with_data)
      servers = get_user_servers(user_with_data)

      socket =
        assign(socket,
          pm_expanded: true,
          servers_expanded: true,
          private_messages: private_messages,
          servers: servers
        )

      {:ok, socket}
    else
      # Handle case when no current_user is provided
      # This should NOT happen!
      {:ok,
       assign(socket,
         pm_expanded: true,
         servers_expanded: true,
         private_messages: [],
         joined_servers: [],
         owned_servers: []
       )}
    end
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
  end

  defp get_user_servers(user) do
    owned = user.owned_servers || []
    joined = user.joined_servers || []

    user_id = user.id

    servers =
      (owned ++ joined)
      |> Enum.uniq_by(fn server -> server.id end)
      |> Enum.sort_by(fn server -> server.name end)
      |> Vyre.Repo.preload(:channels)

    # Enhance channels with unread status and mention count
    Enum.map(servers, fn server ->
      channels =
        Enum.map(server.channels, fn channel ->
          # Add computed properties to each channel
          Map.put(channel, :computed, %{
            has_unread: Vyre.Channels.channel_has_unread?(user_id, channel.id),
            mention_count: Vyre.Channels.get_channel_mention_count(user_id, channel.id)
          })
        end)

      %{server | channels: channels}
    end)
  end

  # Event handlers
  def handle_event("toggle_pm", _, socket) do
    {:noreply, assign(socket, pm_expanded: !socket.assigns.pm_expanded)}
  end

  def handle_event("toggle_servers", _, socket) do
    {:noreply, assign(socket, servers_expanded: !socket.assigns.servers_expanded)}
  end

  def handle_event("open_commands", _, socket) do
    send(self(), {:open_commands})
    {:noreply, socket}
  end

  def handle_event("open_settings", _, socket) do
    send(self(), {:open_settings})
    {:noreply, socket}
  end
end
