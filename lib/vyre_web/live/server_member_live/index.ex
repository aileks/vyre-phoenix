defmodule VyreWeb.ServerMemberLive.Index do
  use VyreWeb, :live_view

  alias Vyre.Servers
  alias Vyre.Servers.ServerMember

  @impl true
  def mount(_params, _session, socket) do
    {:ok, stream(socket, :server_members, Servers.list_server_members())}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit Server member")
    |> assign(:server_member, Servers.get_server_member!(id))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Server member")
    |> assign(:server_member, %ServerMember{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing Server members")
    |> assign(:server_member, nil)
  end

  @impl true
  def handle_info({VyreWeb.ServerMemberLive.FormComponent, {:saved, server_member}}, socket) do
    {:noreply, stream_insert(socket, :server_members, server_member)}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    server_member = Servers.get_server_member!(id)
    {:ok, _} = Servers.delete_server_member(server_member)

    {:noreply, stream_delete(socket, :server_members, server_member)}
  end
end
