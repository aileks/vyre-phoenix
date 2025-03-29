defmodule VyreWeb.ChannelLive.Show do
  use VyreWeb, :live_view

  alias Vyre.Channels
  alias Vyre.Messages

  @impl true
  def mount(%{"id" => channel_id}, _session, socket) do
    if connected?(socket) do
      Phoenix.PubSub.subscribe(Vyre.PubSub, "channel:#{channel_id}")
    end

    # Fetch the channel and its messages
    channel = Channels.get_channel!(channel_id)
    messages = Messages.list_channel_messages(channel_id)

    {:ok,
     socket
     |> assign(:channel, channel)
     |> assign(:messages, messages)
     |> assign(:current_user, socket.assigns.current_user)
     |> assign(:message_form, to_form(%{"content" => ""}))}
  end

  @impl true
  def handle_params(%{"id" => id}, _, socket) do
    {:noreply,
     socket
     |> assign(:page_title, "#{socket.assigns.channel.name} | Vyre")
     |> assign(:id, id)}
  end

  @impl true
  def handle_event("send_message", %{"content" => content}, socket) do
    user_id = socket.assigns.current_user.id
    channel_id = socket.assigns.channel.id

    {:ok, message} =
      Messages.create_message(%{
        content: content,
        user_id: user_id,
        channel_id: channel_id,
        edited: false,
        mentions_everyone: String.contains?(content, "@everyone")
      })

    # Mark channel as read for this user
    Channels.mark_channel_as_read(user_id, channel_id)

    # Broadcast the new message to all subscribers
    Phoenix.PubSub.broadcast(
      Vyre.PubSub,
      "channel:#{channel_id}",
      {:new_message, Messages.get_message_with_user(message.id)}
    )

    {:noreply,
     socket
     |> assign(:message_form, to_form(%{"content" => ""}))
     |> update(:messages, fn messages -> messages ++ [message] end)}
  end

  @impl true
  def handle_info({:new_message, message}, socket) do
    # We should only append the message if it's not already in our list
    message_ids = Enum.map(socket.assigns.messages, & &1.id)

    if message.id in message_ids do
      {:noreply, socket}
    else
      {:noreply, update(socket, :messages, fn messages -> messages ++ [message] end)}
    end
  end
end
