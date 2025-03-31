defmodule VyreWeb.ChannelLive.Show do
  use VyreWeb, :live_view

  alias Vyre.Channels
  alias Vyre.Messages
  alias Vyre.Servers

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    if String.starts_with?(id, "u-") do
      # Handle private message case
      other_user_id = String.replace_prefix(id, "u-", "")
      mount_private_messages(other_user_id, socket)
    else
      # Handle regular channel case
      channel_id = id
      mount_channel(channel_id, socket)
    end
  end

  def mount_private_messages(other_user_id, socket) do
    current_user_id = socket.assigns.current_user.id

    if connected?(socket) do
      Phoenix.PubSub.subscribe(
        Vyre.PubSub,
        Messages.conversation_topic(current_user_id, other_user_id)
      )

      if !socket.assigns[:status_subscribed] do
        user_id = socket.assigns.current_user.id
        Phoenix.PubSub.subscribe(Vyre.PubSub, "user:#{user_id}:status")
        assign(socket, :status_subscribed, true)
      end

      # Mark messages as read when entering the conversation
      Task.start(fn ->
        Messages.mark_private_messages_as_read(current_user_id, other_user_id)
      end)
    end

    other_user = Vyre.Accounts.get_user!(other_user_id)

    messages = Messages.list_private_messages_between(current_user_id, other_user_id)
    has_messages = length(messages) > 0

    {:ok,
     socket
     |> assign(:current_user, socket.assigns.current_user)
     |> assign(:has_messages, has_messages)
     |> assign(:pm_mode, true)
     |> assign(:other_user, other_user)
     |> assign(:channel, nil)
     |> stream(:messages, messages, dom_id: &"message-#{&1.id}")
     |> assign(:message_form, to_form(%{"content" => ""}))}
  end

  def mount_channel(channel_id, socket) do
    # Existing channel mount code goes here
    if connected?(socket) do
      Phoenix.PubSub.subscribe(Vyre.PubSub, "channel:#{channel_id}")
      Phoenix.PubSub.subscribe(Vyre.PubSub, "user:#{socket.assigns.current_user.id}:status")
    end

    # Fetch the channel and its messages
    channel = Channels.get_channel!(channel_id)
    messages = Messages.list_channel_messages(channel_id)
    has_messages = messages != []

    {:ok,
     socket
     |> assign(:current_user, socket.assigns.current_user)
     |> assign(:has_messages, has_messages)
     # Flag to indicate channel mode
     |> assign(:pm_mode, false)
     |> assign(:channel, channel)
     |> stream(:messages, messages, dom_id: &"message-#{&1.id}")
     |> assign(:message_form, to_form(%{"content" => ""}))}
  end

  @impl true
  def handle_params(%{"id" => id}, _, socket) do
    user_id = socket.assigns.current_user.id

    if String.starts_with?(id, "u-") do
      # Private message handling
      other_user_id = String.replace_prefix(id, "u-", "")

      if connected?(socket) do
        # Mark private messages as read
        Vyre.Messages.mark_private_messages_as_read(user_id, other_user_id)
      end

      {:noreply, socket}
    else
      # Regular channel handling
      channel_id = id

      if connected?(socket) do
        status_params = %{
          user_id: user_id,
          channel_id: channel_id,
          last_read_at: DateTime.utc_now(),
          last_read_message_id: nil
        }

        Vyre.Channels.StatusCache.update_status(user_id, channel_id, status_params)
        status_update = %{has_unread: false}

        Phoenix.PubSub.broadcast(
          Vyre.PubSub,
          "user:#{user_id}:status",
          {:channel_status_update, user_id, channel_id, status_update}
        )

        Task.start(fn ->
          Channels.mark_channel_as_read(user_id, channel_id)
        end)
      end

      {:noreply, socket}
    end
  end

  # @impl true
  # def handle_params(%{"id" => id}, uri, socket) do
  #   user_id = socket.assigns.current_user.id
  #   channel_id = id
  #   current_path = URI.parse(uri).path

  #   if connected?(socket) do
  #     status_params = %{
  #       user_id: user_id,
  #       channel_id: channel_id,
  #       last_read_at: DateTime.utc_now(),
  #       # mention_count: 0,
  #       # Will be filled by the task
  #       last_read_message_id: nil
  #     }

  #     Vyre.Channels.StatusCache.update_status(user_id, channel_id, status_params)

  #     # status_update = %{has_unread: false, mention_count: 0}
  #     status_update = %{has_unread: false}

  #     Phoenix.PubSub.broadcast(
  #       Vyre.PubSub,
  #       "user:#{user_id}:status",
  #       {:channel_status_update, user_id, channel_id, status_update}
  #     )

  #     Task.start(fn ->
  #       Channels.mark_channel_as_read(user_id, channel_id)
  #     end)
  #   end

  #   {:noreply, assign(socket, :current_path, current_path)}
  # end

  @impl true
  def handle_event("send_message", %{"content" => content}, socket) do
    user_id = socket.assigns.current_user.id

    if socket.assigns.pm_mode do
      other_user_id = socket.assigns.other_user.id

      {:ok, message} =
        Messages.create_and_broadcast_private_message(%{
          content: content,
          sender_id: user_id,
          receiver_id: other_user_id,
          read: false
        })

      {:noreply,
       socket
       |> assign(:has_messages, true)
       |> assign(:message_form, to_form(%{"content" => ""}))
       |> push_event("clear_input", %{})
       |> stream_insert(:messages, message)}
    else
      channel_id = socket.assigns.channel.id

      {:ok, message} =
        Messages.create_message(%{
          content: content,
          user_id: user_id,
          channel_id: channel_id,
          mentions_everyone: String.contains?(content, "@everyone")
        })

      message_with_user = Messages.get_message_with_user(message.id)

      # Broadcast to channel subscribers
      Phoenix.PubSub.broadcast(
        Vyre.PubSub,
        "channel:#{channel_id}",
        {:new_message, message_with_user}
      )

      # Broadcast unread status to all server members EXCEPT sender
      Task.start(fn ->
        channel = Channels.get_channel!(channel_id)
        server_members = Servers.list_server_members(channel.server_id)

        Enum.each(server_members, fn member ->
          unless member.user_id == user_id do
            # mention_count = if message.mentions_everyone, do: 1, else: 0

            # Broadcast unread status to this member
            Phoenix.PubSub.broadcast(
              Vyre.PubSub,
              "user:#{member.user_id}:status",
              {:channel_status_update, member.user_id, channel_id, %{has_unread: true}}
            )

            # Phoenix.PubSub.broadcast(
            #   Vyre.PubSub,
            #   "user:#{member.user_id}:status",
            #   {:channel_status_update, member.user_id, channel_id,
            #    %{has_unread: true, mention_count: mention_count}}
            # )
          end
        end)
      end)

      {:noreply,
       socket
       |> assign(:has_messages, true)
       |> assign(:message_form, to_form(%{"content" => ""}))
       |> push_event("clear_input", %{})
       |> stream_insert(:messages, message_with_user)}
    end
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

      # Only if we're not currently viewing this channel
      if socket.assigns.channel.id != channel_id do
        # mention_count = if message.mentions_everyone, do: 1, else: 0

        # Cache invalidation - this will force a re-fetch of status
        :ets.delete(:channel_status_cache, "#{user_id}:#{channel_id}")

        # status_update = %{has_unread: true, mention_count: mention_count}
        status_update = %{has_unread: true}

        Phoenix.PubSub.broadcast(
          Vyre.PubSub,
          "user:#{user_id}:status",
          {:channel_status_update, user_id, channel_id, status_update}
        )
      end

      {:noreply,
       socket
       |> assign(:has_messages, true)
       |> stream_insert(:messages, message_with_user)}
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_info({:channel_status_update, user_id, channel_id, status}, socket) do
    if socket.assigns.current_user.id == user_id do
      VyreWeb.SidebarState.update_channel_status(user_id, channel_id, status)
      updated_servers = VyreWeb.SidebarState.get_state(user_id).servers
      {:noreply, assign(socket, servers: updated_servers)}
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_info({:new_private_message, message}, socket) do
    current_user_id = socket.assigns.current_user.id

    # Only process if we're in PM mode
    if socket.assigns.pm_mode do
      other_user_id = socket.assigns.other_user.id

      # Check if this message belongs to our current conversation
      message_belongs_to_conversation =
        (message.sender_id == current_user_id && message.receiver_id == other_user_id) ||
          (message.sender_id == other_user_id && message.receiver_id == current_user_id)

      if message_belongs_to_conversation do
        # Determine if incoming message (from other user to current user)
        is_incoming = message.sender_id != current_user_id

        # Mark as read if incoming
        if is_incoming do
          Task.start(fn ->
            Messages.mark_private_messages_as_read(current_user_id, other_user_id)
          end)
        end

        # Process the message
        {:noreply,
         socket
         |> assign(:has_messages, true)
         |> stream_insert(:messages, message)}
      else
        # Message doesn't belong to this conversation
        {:noreply, socket}
      end
    else
      # Not in PM mode
      {:noreply, socket}
    end
  end

  def handle_info({:private_message_unread, sender_id}, socket) do
    VyreWeb.SidebarState.update_private_message_status(
      socket.assigns.current_user.id,
      sender_id,
      true
    )

    {:noreply, socket}
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
