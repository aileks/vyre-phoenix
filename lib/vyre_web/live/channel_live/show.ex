defmodule VyreWeb.ChannelLive.Show do
  use VyreWeb, :live_view

  alias Vyre.Channels
  alias Vyre.Messages

  @impl true
  def mount(%{"id" => channel_id}, _session, socket) do
    if connected?(socket) do
      Phoenix.PubSub.subscribe(Vyre.PubSub, "channel:#{channel_id}")

      Phoenix.PubSub.subscribe(
        Vyre.PubSub,
        "user:#{socket.assigns.current_user.id}:status"
      )
    end

    # Fetch the channel and its messages
    channel = Channels.get_channel!(channel_id)
    messages = Messages.list_channel_messages(channel_id)
    has_messages = messages != []

    {:ok,
     socket
     |> assign(:current_user, socket.assigns.current_user)
     |> assign(:has_messages, has_messages)
     |> assign(:channel, channel)
     |> stream(:messages, messages, dom_id: &"message-#{&1.id}")
     |> assign(:message_form, to_form(%{"content" => ""}))}
  end

  @impl true
  def handle_params(%{"id" => id}, _, socket) do
    if connected?(socket) do
      user_id = socket.assigns.current_user.id

      status = %{has_unread: false, mention_count: 0}

      Phoenix.PubSub.broadcast(
        Vyre.PubSub,
        "user:#{user_id}:status",
        {:channel_status_update, id, status}
      )

      Task.start(fn ->
        Vyre.Channels.mark_channel_as_read(user_id, id)
      end)
    end

    {:noreply, socket}
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

    Phoenix.PubSub.broadcast(
      Vyre.PubSub,
      "channel:#{channel_id}",
      {:new_message, message_with_user}
    )

    {:noreply,
     socket
     |> assign(:has_messages, true)
     |> assign(:message_form, to_form(%{"content" => ""}))
     |> push_event("clear_input", %{})
     |> stream_insert(:messages, message_with_user)}
  end

  @impl true
  def handle_event("mark_as_read", %{"channel_id" => channel_id}, socket) do
    user_id = socket.assigns.current_user.id

    # Update optimistically
    socket =
      update_in(socket.assigns.channels, fn channels ->
        Enum.map(channels, fn channel ->
          if channel.id == channel_id do
            put_in(channel.computed.has_unread, false)
            |> put_in([Access.key(:computed), Access.key(:mention_count)], 0)
          else
            channel
          end
        end)
      end)

    # Async task to update with server
    Task.start(fn ->
      Vyre.Channels.mark_channel_as_read(user_id, channel_id)
    end)

    {:noreply, socket}
  end

  @impl true
  def handle_info({:new_message, message}, socket) do
    # We only need to check if it's from another user
    # since our own messages are already handled in handle_event
    if message.user_id != socket.assigns.current_user.id do
      message_with_user = Messages.get_message_with_user(message.id)
      channel_id = message.channel_id
      user_id = socket.assigns.current_user.id

      :ets.delete(:channel_status_cache, "#{user_id}:#{channel_id}")

      {:noreply,
       socket
       |> assign(:has_messages, true)
       |> stream_insert(:messages, message_with_user)}
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_info({:channel_status_update, channel_id, status}, socket) do
    # Only try to update channels if the socket has a channels assign
    if Map.has_key?(socket.assigns, :channels) do
      socket =
        update_in(socket.assigns.channels, fn channels ->
          Enum.map(channels, fn channel ->
            if channel.id == channel_id do
              put_in(channel.computed.has_unread, status.has_unread)
              |> put_in([Access.key(:computed), Access.key(:mention_count)], status.mention_count)
            else
              channel
            end
          end)
        end)

      {:noreply, socket}
    else
      if socket.assigns[:channel] && socket.assigns.channel.id == channel_id do
        socket = assign(socket, current_channel_status: status)
        {:noreply, socket}
      else
        {:noreply, socket}
      end
    end
  end

  def format_message_date(naive_datetime) do
    now = NaiveDateTime.utc_now() |> NaiveDateTime.to_date()
    message_date = NaiveDateTime.to_date(naive_datetime)
    formatted_time = format_time(NaiveDateTime.to_time(naive_datetime))

    cond do
      message_date == now ->
        formatted_time

      message_date == Date.add(now, -1) ->
        "Yesterday at #{formatted_time}"

      true ->
        formatted_date = format_date(message_date)
        "#{formatted_date}, #{formatted_time}"
    end
  end

  defp format_time(%Time{hour: hour, minute: minute}) do
    period = if hour >= 12, do: "PM", else: "AM"
    formatted_hour = if hour > 12, do: hour - 12, else: if(hour == 0, do: 12, else: hour)
    "#{formatted_hour}:#{String.pad_leading("#{minute}", 2, "0")} #{period}"
  end

  defp format_date(%Date{year: year, month: month, day: day}) do
    "#{String.pad_leading("#{month}", 2, "0")}/#{String.pad_leading("#{day}", 2, "0")}/#{year}"
  end
end
