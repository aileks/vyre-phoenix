defmodule VyreWeb.SidebarHook do
  import Phoenix.LiveView

  def on_mount(:default, _params, _session, socket) do
    if socket.assigns[:current_user] && connected?(socket) do
      user_id = socket.assigns.current_user.id
      Phoenix.PubSub.subscribe(Vyre.PubSub, "user:#{user_id}:status")
      VyreWeb.SidebarState.load_for_user(socket.assigns.current_user)

      {:cont, attach_hook(socket, :sidebar_status_updates, :handle_info, &handle_status_update/2)}
    else
      {:cont, socket}
    end
  end

  def handle_status_update({:channel_status_update, user_id, channel_id, status}, socket) do
    if user_id == socket.assigns.current_user.id do
      VyreWeb.SidebarState.update_channel_status(user_id, channel_id, status)

      # send_update(VyreWeb.Components.Sidebar, id: "sidebar", status_update: {channel_id, status})
      #
      send_update(VyreWeb.Components.Sidebar,
        id: "sidebar-#{user_id}",
        status_update: {channel_id, status}
      )

      {:cont, socket}
    else
      {:cont, socket}
    end
  end

  # Pass through other messages
  def handle_status_update(_message, socket), do: {:cont, socket}
end
