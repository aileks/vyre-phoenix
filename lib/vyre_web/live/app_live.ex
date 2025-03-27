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
      |> assign(:show_settings, params["settings"] == "true")
      |> assign(:show_commands, params["commands"] == "true")

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
            <p class="text-xl">Welcome to Vyre Chat</p>
        <% end %>
      </div>

      <%= if @show_settings do %>
        <.live_component
          module={VyreWeb.Components.SettingsModal}
          id="settings-modal"
          is_open={true}
          return_to={~p"/app"}
        />
      <% end %>

      <%= if @show_commands do %>
        <.live_component
          module={VyreWeb.Components.CommandsModal}
          id="commands-modal"
          is_open={true}
          return_to={~p"/app"}
        />
      <% end %>
    </div>
    """
  end

  def handle_event("open_settings", _, socket) do
    {:noreply, assign(socket, show_settings: true)}
  end

  def handle_event("open_commands", _, socket) do
    {:noreply, assign(socket, show_commands: true)}
  end
end
