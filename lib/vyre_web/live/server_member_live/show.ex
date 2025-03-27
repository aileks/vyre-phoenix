defmodule VyreWeb.ServerMemberLive.Show do
  use VyreWeb, :live_view

  alias Vyre.Servers

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"id" => id}, _, socket) do
    {:noreply,
     socket
     |> assign(:page_title, page_title(socket.assigns.live_action))
     |> assign(:server_member, Servers.get_server_member!(id))}
  end

  defp page_title(:show), do: "Show Server member"
  defp page_title(:edit), do: "Edit Server member"
end
