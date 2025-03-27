defmodule VyreWeb.AppLive do
  use VyreWeb, :live_view

  def mount(_params, _session, socket) do
    socket =
      assign(socket,
        page_title: "Vyre Chat",
        current_uri: socket.assigns[:uri] || "/"
      )

    {:ok, socket}
  end

  def handle_params(_params, uri, socket) do
    socket = assign(socket, :current_uri, uri)
    {:noreply, socket}
  end

  def render(assigns) do
    ~H"""
    <div class="flex h-full w-full items-center justify-center">
      <%= case @live_action do %>
        <% :friends -> %>
          <p>Friends page goes here</p>
        <% :channels -> %>
          <p>Channel {@channel_id} goes here</p>
        <% :settings -> %>
          <p>Settings modal goes here</p>
        <% :commands -> %>
          <p>Commands modal goes here</p>
        <% _ -> %>
          <p class="text-xl">Welcome to Vyre Chat</p>
      <% end %>
    </div>
    """
  end

  # Keyboard shortcuts (to be implemented)
  def handle_event("keydown", %{"key" => "k", "ctrlKey" => true}, socket) do
    {:noreply, push_patch(socket, to: ~p"/app/commands")}
  end

  def handle_event("keydown", %{"key" => ",", "ctrlKey" => true}, socket) do
    {:noreply, push_patch(socket, to: ~p"/app/settings")}
  end
end
