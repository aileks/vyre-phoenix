defmodule VyreWeb.AppLive do
  use VyreWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) && socket.assigns[:current_user] do
      user_id = socket.assigns.current_user.id
      IO.puts("\n\nLIVEVIEW MOUNT: Subscribing to user:#{user_id}:status")
      Phoenix.PubSub.subscribe(Vyre.PubSub, "user:#{user_id}:status")
    end

    socket =
      assign(socket,
        page_title: "Vyre Chat",
        current_path: "/app",
        current_uri: socket.assigns[:uri] || "/app",
        show_settings: false,
        show_commands: false
      )

    {:ok, socket}
  end

  @impl true
  def handle_params(params, uri, socket) do
    socket =
      socket
      |> assign(:current_path, URI.parse(uri).path)
      |> assign(:current_uri, uri)
      |> assign(:id, params["id"])

    {:noreply, socket}
  end

  @impl true
  def handle_event("close_modal", %{"id" => "settings-modal"}, socket) do
    {:noreply, assign(socket, show_settings: false)}
  end

  @impl true
  def handle_event("close_modal", %{"id" => "commands-modal"}, socket) do
    {:noreply, assign(socket, show_commands: false)}
  end

  @impl true
  def handle_info({:open_commands}, socket) do
    {:noreply, assign(socket, show_commands: true, show_settings: false)}
  end

  @impl true
  def handle_info({:open_settings}, socket) do
    {:noreply, assign(socket, show_settings: true, show_commands: false)}
  end

  @impl true
  def handle_info({:close_commands}, socket) do
    {:noreply, assign(socket, show_commands: false)}
  end

  @impl true
  def handle_info({:close_settings}, socket) do
    {:noreply, assign(socket, show_settings: false)}
  end

  @impl true
  def handle_info({:channel_status_update, channel_id, status}, socket) do
    IO.puts("\n\nLIVEVIEW DEBUG: Received status update, forwarding to sidebar")

    send_update(VyreWeb.Components.Sidebar, id: "sidebar", status_update: {channel_id, status})
    {:noreply, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div id="app-container">
      <div class="flex h-full w-full items-center justify-center">
        <%= case @live_action do %>
          <% :friends -> %>
            <p>Friends page goes here</p>
          <% :channels -> %>
            <p>Channel {@channel_id} goes here</p>
          <% _ -> %>
            <p class="text-xl">Welcome to Vyre</p>
        <% end %>
      </div>

      <%= if @show_settings do %>
        <.live_component
          module={VyreWeb.Components.SettingsModal}
          id="settings-modal"
          is_open={true}
          return_to={@current_path}
        />
      <% end %>

      <%= if @show_commands do %>
        <.live_component
          module={VyreWeb.Components.CommandsModal}
          id="commands-modal"
          is_open={true}
          return_to={@current_path}
        />
      <% end %>
    </div>
    """
  end
end
