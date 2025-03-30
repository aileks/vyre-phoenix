alias Vyre.Repo
alias Vyre.Factory
alias Vyre.Servers.Server
alias Vyre.Servers.ServerMember
alias Vyre.Channels.UserChannelStatus
import Ecto.Query

Application.ensure_all_started(:faker)

users = Factory.insert_list(30, :user)

owners = Enum.take_random(users, 10)

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

    Factory.insert(:private_message,
      sender_id: sender.id,
      receiver_id: receiver.id,
      content: Faker.Lorem.paragraph()
    )
  end)
end)

# Set random status for some users (others will remain with default status "offline")
status_options = ["online", "away", "busy", "offline"]

# Select about 30% of users to have non-offline status
active_users = Enum.take_random(users, trunc(length(users) * 0.3))

Enum.each(active_users, fn user ->
  user
  |> Ecto.Changeset.change(%{status: Enum.random(status_options)})
  |> Repo.update!()
end)

# Helper function for more natural time distribution
random_activity_time = fn ->
  # Distribution of activity times:
  # - 60% within the last day
  # - 30% within the last week
  # - 10% older than a week
  case :rand.uniform(10) do
    n when n <= 6 -> DateTime.add(DateTime.utc_now(), -1 * :rand.uniform(86400))
    n when n <= 9 -> DateTime.add(DateTime.utc_now(), -1 * (:rand.uniform(6) * 86400 + 86400))
    _ -> DateTime.add(DateTime.utc_now(), -1 * ((:rand.uniform(30) + 7) * 86400))
  end
end

Enum.each(channels, fn channel ->
  # Get all members of the server this channel belongs to
  server_members =
    Repo.all(
      from sm in Vyre.Servers.ServerMember,
        where: sm.server_id == ^channel.server_id,
        preload: [:user]
    )

  # Get messages in this channel with timestamps
  messages =
    Repo.all(
      from m in Vyre.Messages.Message,
        where: m.channel_id == ^channel.id,
        order_by: [asc: m.inserted_at],
        preload: [:user]
    )

  unless Enum.empty?(messages) do
    # For each member, create appropriate UserChannelStatus
    Enum.each(server_members, fn member ->
      user_id = member.user.id

      # Determine activity level for this user/channel
      activity_type =
        Enum.random([
          # Regularly checks channel
          :active,
          # Occasionally checks channel
          :casual,
          # Rarely checks, but does read sometimes
          :lurker,
          # Has read historically but inactive lately
          :inactive,
          # Recently joined, not much history
          :new_member,
          # Never reads this channel
          :total_inactive
        ])

      # Calculate read status based on activity type
      {last_read_at, last_read_message_id, mention_count} =
        case activity_type do
          :active ->
            random_offset =
              if length(messages) > 0,
                do: :rand.uniform(max(1, min(3, length(messages)))),
                else: 0

            message_idx = length(messages) - random_offset
            message = Enum.at(messages, max(0, message_idx))

            # Count mentions after last read
            newer_messages = Enum.drop(messages, message_idx + 1)

            mention_count =
              Enum.count(newer_messages, fn msg ->
                msg.mentions_everyone && msg.user_id != user_id
              end)

            {message.inserted_at, message.id, mention_count}

          :casual ->
            random_offset =
              if length(messages) > 0,
                do: :rand.uniform(max(1, min(5, trunc(length(messages) * 0.3)))),
                else: 0

            message_idx = trunc(length(messages) * 0.7) - random_offset

            message = Enum.at(messages, max(0, message_idx))
            newer_messages = Enum.drop(messages, message_idx + 1)

            mention_count =
              Enum.count(newer_messages, fn msg ->
                msg.mentions_everyone && msg.user_id != user_id
              end)

            {message.inserted_at, message.id, mention_count}

          :lurker ->
            random_offset =
              if length(messages) > 0,
                do: :rand.uniform(max(1, min(3, trunc(length(messages) * 0.2)))),
                else: 0

            message_idx = trunc(length(messages) * 0.4) - random_offset

            message = Enum.at(messages, max(0, message_idx))
            newer_messages = Enum.drop(messages, message_idx + 1)

            mention_count =
              Enum.count(newer_messages, fn msg ->
                msg.mentions_everyone && msg.user_id != user_id
              end)

            {message.inserted_at, message.id, mention_count}

          :inactive ->
            message_idx =
              if length(messages) > 0,
                do: :rand.uniform(max(1, min(3, length(messages)))),
                else: 1

            message = Enum.at(messages, max(0, message_idx - 1))
            newer_messages = Enum.drop(messages, message_idx)

            # More mentions for inactive users to show buildup
            mention_count =
              Enum.count(newer_messages, fn msg ->
                msg.mentions_everyone && msg.user_id != user_id
              end)

            {message.inserted_at, message.id, mention_count}

          :new_member ->
            # New member - no history yet
            {DateTime.add(DateTime.utc_now(), -86400), nil, 0}

          :total_inactive ->
            mention_count =
              Enum.count(messages, fn msg ->
                msg.mentions_everyone && msg.user_id != user_id
              end)

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
  end
end)

all_private_messages = Repo.all(Vyre.Messages.PrivateMessage)

# Group messages by conversation (user pairs)
conversations =
  Enum.group_by(
    all_private_messages,
    fn msg ->
      participants = [msg.sender_id, msg.receiver_id] |> Enum.sort() |> Enum.join("-")
      participants
    end
  )

# Add some targeted mentions
Enum.each(users, fn user ->
  # Select a few random channels (1-3) where this user got mentioned
  user_server_memberships =
    Repo.all(
      from sm in Vyre.Servers.ServerMember,
        where: sm.user_id == ^user.id,
        select: sm.server_id
    )

  potential_channels =
    Repo.all(
      from c in Vyre.Channels.Channel,
        where: c.server_id in ^user_server_memberships
    )

  if length(potential_channels) > 0 do
    mention_count = :rand.uniform(min(3, length(potential_channels)))
    mention_channels = Enum.take_random(potential_channels, mention_count)

    Enum.each(mention_channels, fn channel ->
      # Get existing status if any
      status = Repo.get_by(UserChannelStatus, user_id: user.id, channel_id: channel.id)

      if status do
        # Increase existing mention count
        new_mention_count = status.mention_count + :rand.uniform(5)

        status
        |> Ecto.Changeset.change(%{mention_count: new_mention_count})
        |> Repo.update!()
      end
    end)
  end
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
