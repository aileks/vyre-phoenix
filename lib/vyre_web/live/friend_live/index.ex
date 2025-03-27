defmodule VyreWeb.FriendLive.Index do
  use VyreWeb, :live_view

  alias Vyre.Friends
  alias Vyre.Friends.Friend

  @impl true
  def mount(_params, _session, socket) do
    {:ok, stream(socket, :friends, Friends.list_friends())}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit Friend")
    |> assign(:friend, Friends.get_friend!(id))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Friend")
    |> assign(:friend, %Friend{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing Friends")
    |> assign(:friend, nil)
  end

  @impl true
  def handle_info({VyreWeb.FriendLive.FormComponent, {:saved, friend}}, socket) do
    {:noreply, stream_insert(socket, :friends, friend)}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    friend = Friends.get_friend!(id)
    {:ok, _} = Friends.delete_friend(friend)

    {:noreply, stream_delete(socket, :friends, friend)}
  end
end
