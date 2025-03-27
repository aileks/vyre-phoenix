defmodule VyreWeb.PrivateMessageLive.Index do
  use VyreWeb, :live_view

  alias Vyre.Messages
  alias Vyre.Messages.PrivateMessage

  @impl true
  def mount(_params, _session, socket) do
    {:ok, stream(socket, :private_messages, Messages.list_private_messages())}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit Private message")
    |> assign(:private_message, Messages.get_private_message!(id))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Private message")
    |> assign(:private_message, %PrivateMessage{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing Private messages")
    |> assign(:private_message, nil)
  end

  @impl true
  def handle_info({VyreWeb.PrivateMessageLive.FormComponent, {:saved, private_message}}, socket) do
    {:noreply, stream_insert(socket, :private_messages, private_message)}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    private_message = Messages.get_private_message!(id)
    {:ok, _} = Messages.delete_private_message(private_message)

    {:noreply, stream_delete(socket, :private_messages, private_message)}
  end
end
