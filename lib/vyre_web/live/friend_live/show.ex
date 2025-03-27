defmodule VyreWeb.FriendLive.Show do
  use VyreWeb, :live_view

  alias Vyre.Friends

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"id" => id}, _, socket) do
    {:noreply,
     socket
     |> assign(:page_title, page_title(socket.assigns.live_action))
     |> assign(:friend, Friends.get_friend!(id))}
  end

  defp page_title(:show), do: "Show Friend"
  defp page_title(:edit), do: "Edit Friend"
end
