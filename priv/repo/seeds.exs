alias Vyre.Repo
alias Vyre.Factory
alias Vyre.Servers.Server
alias Vyre.Servers.ServerMember
alias Vyre.Channels.UserChannelStatus
import Ecto.Query

Application.ensure_all_started(:faker)

users = Factory.insert_list(20, :user)

owners = Enum.take_random(users, 5)

Enum.each(owners, fn owner ->
  num_servers = Enum.random(1..3)

  Enum.each(1..num_servers, fn _ ->
    Factory.insert(:server, owner_id: owner.id)
  end)
end)

# Get all servers for other seeders
servers = Repo.all(Server)

channels =
  for server <- servers do
    num_channels = Enum.random(1..8)

    Enum.map(1..num_channels, fn _ ->
      Factory.insert(:channel, server_id: server.id)
    end)
  end

# Flatten the list in case it's nested.
channels = List.flatten(channels)

Enum.each(servers, fn server ->
  unless Repo.get_by(ServerMember, user_id: server.owner_id, server_id: server.id) do
    Factory.insert(:server_member, user_id: server.owner_id, server_id: server.id)
  end
end)

Enum.each(servers, fn server ->
  potential_members = Enum.filter(users, fn user -> user.id != server.owner_id end)

  num_members = Enum.random(3..10)
  members_to_add = Enum.take_random(potential_members, num_members)

  Enum.each(members_to_add, fn user ->
    unless Repo.get_by(ServerMember, user_id: user.id, server_id: server.id) do
      Factory.insert(:server_member,
        user_id: user.id,
        server_id: server.id,
        nickname: user.display_name
      )
    end
  end)
end)

Enum.each(channels, fn channel ->
  num_messages = Enum.random(1..10)

  Enum.each(1..num_messages, fn _ ->
    user = Enum.random(users)
    Factory.insert(:message, channel_id: channel.id, user_id: user.id)
  end)
end)

all_possible_pairs = for u <- users, f <- users, u.id != f.id, do: {u.id, f.id}

pairs_to_insert =
  all_possible_pairs
  |> Enum.shuffle()
  |> Enum.take(10)

Enum.each(pairs_to_insert, fn {user_id, friend_id} ->
  Factory.insert(:friend, user_id: user_id, friend_id: friend_id)
end)

# Create default Member role for each server
Enum.each(servers, fn server ->
  default_role = Repo.get_by(Vyre.Roles.Role, server_id: server.id, name: "Member")

  default_role =
    if default_role do
      default_role
    else
      Factory.insert(:role,
        server_id: server.id,
        name: "Member",
        color: "#99AABB",
        position: 0,
        permissions: 1,
        hoist: false,
        mentionable: false
      )
    end

  server_members = Repo.all(from sm in ServerMember, where: sm.server_id == ^server.id)

  # Assign the default role to all members of the server
  Enum.each(server_members, fn member ->
    unless Repo.get_by(Vyre.Roles.UserRole, user_id: member.user_id, role_id: default_role.id) do
      Factory.insert(:user_role, user_id: member.user_id, role_id: default_role.id)
    end
  end)

  # Create some additional roles for each server
  num_additional_roles = Enum.random(2..4)
  role_names = ["Admin", "Moderator", "VIP", "Contributor", "Regular", "Newcomer"]
  selected_roles = Enum.take_random(role_names, num_additional_roles)

  roles =
    Enum.map(selected_roles, fn role_name ->
      Factory.insert(:role,
        server_id: server.id,
        name: role_name,
        color: Faker.Color.rgb_hex(),
        position: Enum.random(1..5),
        permissions: Enum.random(1..10),
        hoist: Enum.random([true, false]),
        mentionable: Enum.random([true, false])
      )
    end)

  # Assign some additional roles randomly to members
  server_members_without_owner =
    Enum.filter(server_members, fn member ->
      member.user_id != server.owner_id
    end)

  # Give the owner the Admin
  admin_role = Enum.find(roles, fn role -> role.name == "Admin" end)

  if admin_role do
    owner_member = Enum.find(server_members, fn member -> member.user_id == server.owner_id end)

    if owner_member do
      Factory.insert(:user_role, user_id: owner_member.user_id, role_id: admin_role.id)
    end
  end

  # For each additional role, assign it to some random members
  Enum.each(roles, fn role ->
    # Skip if it's the Admin role which was already assigned to the owner
    unless role.name == "Admin" do
      # Assign this role to a random subset of members
      num_to_assign = Enum.random(1..max(1, div(length(server_members_without_owner), 2)))
      members_for_role = Enum.take_random(server_members_without_owner, num_to_assign)

      Enum.each(members_for_role, fn member ->
        Factory.insert(:user_role, user_id: member.user_id, role_id: role.id)
      end)
    end
  end)
end)

# Create some private messages between users
num_private_conversations = 15
user_pairs = for u1 <- users, u2 <- users, u1.id < u2.id, do: {u1, u2}
selected_pairs = Enum.take_random(user_pairs, num_private_conversations)

Enum.each(selected_pairs, fn {user1, user2} ->
  # Generate between 1-10 messages for each conversation
  num_messages = Enum.random(1..10)

  Enum.each(1..num_messages, fn i ->
    # Alternate sender and receiver
    {sender, receiver} = if rem(i, 2) == 0, do: {user1, user2}, else: {user2, user1}

    # Set read status based on position
    is_read = i <= num_messages - 2

    Factory.insert(:private_message,
      sender_id: sender.id,
      receiver_id: receiver.id,
      content: Faker.Lorem.paragraph(),
      read: is_read
    )
  end)
end)

# Helper function to retrieve the latest message
get_last_message = fn channel_id ->
  Repo.one(
    from m in Vyre.Messages.Message,
      where: m.channel_id == ^channel_id,
      order_by: [desc: m.inserted_at],
      limit: 1
  )
end

# Helper function to retrieve all messages for a channel
get_channel_messages = fn channel_id ->
  Repo.all(
    from m in Vyre.Messages.Message,
      where: m.channel_id == ^channel_id,
      order_by: [asc: m.inserted_at]
  )
end

# Get all users with server memberships
server_members = Repo.all(ServerMember) |> Repo.preload(:user)

Enum.each(channels, fn channel ->
  # Get all members of the server this channel belongs to
  channel_server_members =
    Enum.filter(server_members, fn sm ->
      sm.server_id == channel.server_id
    end)

  # Get all messages for this channel
  messages = get_channel_messages.(channel.id)
  last_message = List.last(messages)

  Enum.each(channel_server_members, fn member ->
    user_id = member.user_id

    # Randomize read status
    status_type = Enum.random([:read, :partially_read, :unread])

    # Determine last read message, timestamp and mention count based on status
    {last_read_at, last_read_message_id, mention_count} =
      case status_type do
        :read ->
          if last_message do
            {last_message.inserted_at, last_message.id, 0}
          else
            # Use current time if no messages
            {DateTime.utc_now(), nil, 0}
          end

        :partially_read ->
          if Enum.empty?(messages) do
            # 1 day ago
            {DateTime.add(DateTime.utc_now(), -86400), nil, Enum.random(0..3)}
          else
            idx = max(0, min(floor(length(messages) / 2) - 1, length(messages) - 1))
            message = Enum.at(messages, idx)

            # Count mentions in newer messages
            newer_messages = Enum.drop(messages, idx + 1)

            mention_count =
              Enum.count(newer_messages, fn msg ->
                msg.mentions_everyone && msg.user_id != user_id
              end)

            {message.inserted_at, message.id, mention_count}
          end

        :unread ->
          # For unread, get mentions from all messages not by this user
          mention_count =
            Enum.count(messages, fn msg ->
              msg.mentions_everyone && msg.user_id != user_id
            end)

          # Use a timestamp in the past but nil for last_read_message_id
          # 1 week ago
          {DateTime.add(DateTime.utc_now(), -604_800), nil, mention_count}
      end

    # Ensure all required fields are set
    params = %{
      user_id: user_id,
      channel_id: channel.id,
      last_read_at: last_read_at,
      last_read_message_id: last_read_message_id,
      mention_count: mention_count
    }

    # Double-check the required fields are set
    IO.inspect(params, label: "Creating UserChannelStatus")

    case Repo.get_by(UserChannelStatus, user_id: user_id, channel_id: channel.id) do
      nil ->
        %UserChannelStatus{}
        |> UserChannelStatus.changeset(params)
        |> Repo.insert()

      existing ->
        existing
        |> UserChannelStatus.changeset(params)
        |> Repo.update()
    end
  end)
end)

IO.puts("Database seeded successfully!")
IO.puts("Created:")
IO.puts("  - #{length(users)} users")
IO.puts("  - #{length(servers)} servers")
IO.puts("  - #{length(channels)} channels")
IO.puts("  - #{Repo.aggregate(Vyre.Messages.Message, :count)} messages")
IO.puts("  - #{Repo.aggregate(Vyre.Messages.PrivateMessage, :count)} private messages")
IO.puts("  - #{Repo.aggregate(Vyre.Roles.Role, :count)} roles")
IO.puts("  - #{Repo.aggregate(Vyre.Roles.UserRole, :count)} user roles")
IO.puts("  - #{Repo.aggregate(Vyre.Friends.Friend, :count)} friend relationships")
IO.puts("  - #{Repo.aggregate(UserChannelStatus, :count)} user channel status records")
