defmodule VyreWeb.Components.Sidebar do
  use VyreWeb, :live_component

  @impl true
  def mount(socket) do
    {:ok,
     assign(socket,
       pm_expanded: true,
       all_servers_expanded: true,
       private_messages: [],
       servers: [],
       state_loaded: false
     )}
  end

  @impl true
  def update(assigns, socket) do
    socket = assign(socket, assigns)

    # Only proceed if we have a user and are connected
    if socket.assigns[:current_user] && connected?(socket) do
      state = VyreWeb.SidebarState.get_state()
      servers_list = state.servers || []
      pm_list = state.private_messages || []

      socket =
        socket
        |> assign(:servers, servers_list)
        |> assign(:private_messages, pm_list)
        |> assign(:pm_expanded, state.pm_expanded)
        |> assign(:all_servers_expanded, state.all_servers_expanded)
        |> assign(:state_loaded, true)

      # Subscribe to updates if needed
      socket =
        if !socket.assigns[:status_subscribed] do
          user_id = socket.assigns.current_user.id
          Phoenix.PubSub.subscribe(Vyre.PubSub, "user:#{user_id}:status")
          assign(socket, :status_subscribed, true)
        else
          socket
        end

      {:ok, socket}
    else
      {:ok, socket}
    end
  end

  # Event Handlers
  @impl true
  def handle_event("toggle_pm", _, socket) do
    # Update the shared state
    VyreWeb.SidebarState.update_state(fn state ->
      %{state | pm_expanded: !state.pm_expanded}
    end)

    # Update local state
    {:noreply, assign(socket, pm_expanded: !socket.assigns.pm_expanded)}
  end

  @impl true
  def handle_event("toggle_servers", _, socket) do
    VyreWeb.SidebarState.update_state(fn state ->
      %{state | all_servers_expanded: !state.all_servers_expanded}
    end)

    {:noreply, assign(socket, all_servers_expanded: !socket.assigns.all_servers_expanded)}
  end

  @impl true
  def handle_event("toggle_server", %{"id" => server_id}, socket) do
    # Update the servers list to toggle the specific server
    servers =
      Enum.map(socket.assigns.servers, fn server ->
        if server.id == server_id do
          Map.update(server, :expanded, !server.expanded, &(!&1))
        else
          server
        end
      end)

    # Update the shared state
    VyreWeb.SidebarState.update_state(fn state ->
      %{state | servers: servers}
    end)

    # Update local state
    {:noreply, assign(socket, servers: servers)}
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

  def handle_info(:refresh_sidebar_state, socket) do
    if socket.assigns[:current_user] do
      state = VyreWeb.SidebarState.get_state()

      socket =
        socket
        |> assign(:servers, state.servers)
        |> assign(:private_messages, state.private_messages)
        |> assign(:pm_expanded, state.pm_expanded)
        |> assign(:all_servers_expanded, state.all_servers_expanded)
        |> assign(:state_loaded, true)

      {:noreply, socket}
    else
      {:noreply, socket}
    end
  end

  def handle_info({:channel_status_update, channel_id, status}, socket) do
    updated_servers =
      Enum.map(socket.assigns.servers, fn server ->
        updated_channels =
          Enum.map(server.channels, fn channel ->
            if channel.id == channel_id do
              # Merge the computed status
              current_computed = channel.computed || %{}
              updated_computed = Map.merge(current_computed, status)
              %{channel | computed: updated_computed}
            else
              channel
            end
          end)

        %{server | channels: updated_channels}
      end)

    # Update the shared state
    VyreWeb.SidebarState.update_state(fn state ->
      %{state | servers: updated_servers}
    end)

    # Update local state
    {:noreply, assign(socket, servers: updated_servers)}
  end

  # Forward any other messages to prevent crashes
  def handle_info(_, socket) do
    {:noreply, socket}
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
end
