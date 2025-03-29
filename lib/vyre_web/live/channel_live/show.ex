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
    has_messages = messages != []

    {:ok,
     socket
     |> assign(:channel, channel)
     |> stream(:messages, messages)
     |> assign(:has_messages, has_messages)
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
        mentions_everyone: String.contains?(content, "@everyone")
      })

    Channels.mark_channel_as_read(user_id, channel_id)

    message_with_user = Messages.get_message_with_user(message.id)

    IO.inspect(message_with_user, label: "\n\nNew message from current user")

    Phoenix.PubSub.broadcast(
      Vyre.PubSub,
      "channel:#{channel_id}",
      {:new_message, message_with_user}
    )

    {:noreply,
     socket
     |> assign(:message_form, to_form(%{"content" => ""}))
     |> assign(:has_messages, true)
     |> stream_insert(:messages, message_with_user)}
  end

  @impl true
  def handle_info({:new_message, message}, socket) do
    # We only need to check if it's from another user
    # since our own messages are already handled in handle_event
    if message.user_id != socket.assigns.current_user.id do
      message_with_user = Messages.get_message_with_user(message.id)

      IO.inspect(message_with_user, label: "\n\nNew message")

      {:noreply,
       socket
       |> assign(:has_messages, true)
       |> stream_insert(:messages, message_with_user)}
    else
      {:noreply, socket}
    end
  end
end
