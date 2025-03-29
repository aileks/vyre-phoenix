defmodule VyreWeb.AppLive do
  use VyreWeb, :live_view

  def mount(_params, _session, socket) do
    socket =
      assign(socket,
        page_title: "Vyre Chat",
        current_uri: socket.assigns[:uri] || "/",
        show_settings: false,
        show_commands: false
      )

    {:ok, socket}
  end

  def handle_params(params, uri, socket) do
    socket =
      socket
      |> assign(:current_path, URI.parse(uri).path)
      |> assign(:channel_id, params["channel_id"])

    {:noreply, socket}
  end

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
            <p class="text-xl">Welcome to Vycera</p>
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

  def handle_event("close_modal", %{"id" => "settings-modal"}, socket) do
    {:noreply, assign(socket, show_settings: false)}
  end

  def handle_event("close_modal", %{"id" => "commands-modal"}, socket) do
    {:noreply, assign(socket, show_commands: false)}
  end

  def handle_info({:open_commands}, socket) do
    {:noreply, assign(socket, show_commands: true, show_settings: false)}
  end

  def handle_info({:open_settings}, socket) do
    {:noreply, assign(socket, show_settings: true, show_commands: false)}
  end

  def handle_info({:close_commands}, socket) do
    {:noreply, assign(socket, show_commands: false)}
  end

  def handle_info({:close_settings}, socket) do
    {:noreply, assign(socket, show_settings: false)}
  end
end
