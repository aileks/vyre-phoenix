if Code.ensure_loaded?(ExMachina.Ecto) do
  defmodule Vyre.Factory do
    use ExMachina.Ecto, repo: Vyre.Repo

    # -------------------------------------------------------------------
    # USERS
    # -------------------------------------------------------------------
    def user_factory do
      %Vyre.Accounts.User{
        username: Faker.Internet.user_name(),
        display_name: Faker.Internet.user_name(),
        email: Faker.Internet.email(),
        hashed_password: Bcrypt.hash_pwd_salt("password"),
        avatar_url: Faker.Avatar.image_url(),
        inserted_at: Faker.DateTime.backward(Enum.random(1..30)),
        updated_at: Faker.DateTime.between(~N[2024-12-01T00:00:00Z], ~N[2025-03-01T23:59:59Z])
      }
    end

    # -------------------------------------------------------------------
    # FRIENDS
    # -------------------------------------------------------------------
    def friend_factory do
      %Vyre.Friends.Friend{
        status: Enum.random(["pending", "accepted"]),
        inserted_at: Faker.DateTime.backward(Enum.random(1..30)),
        updated_at: Faker.DateTime.between(~N[2024-12-01T00:00:00Z], ~N[2025-03-01T23:59:59Z])
      }
    end

    # -------------------------------------------------------------------
    # SERVERS
    # -------------------------------------------------------------------
    def server_factory do
      %Vyre.Servers.Server{
        name: Faker.Company.name(),
        description: Faker.Lorem.sentence(),
        icon_url: Faker.Avatar.image_url(),
        inserted_at: Faker.DateTime.backward(Enum.random(1..30)),
        updated_at: Faker.DateTime.between(~N[2024-12-01T00:00:00Z], ~N[2025-03-01T23:59:59Z])
      }
    end

    # -------------------------------------------------------------------
    # SERVER MEMBERS
    # -------------------------------------------------------------------
    def server_member_factory do
      %Vyre.Servers.ServerMember{
        nickname: Enum.random([nil, Faker.Superhero.name(), Faker.Internet.user_name()]),
        inserted_at: Faker.DateTime.backward(Enum.random(1..30))
      }
    end

    # -------------------------------------------------------------------
    # CHANNELS
    # -------------------------------------------------------------------
    def channel_factory do
      %Vyre.Channels.Channel{
        name: Faker.Address.city(),
        description: Faker.Lorem.sentence(),
        topic: Faker.Lorem.sentence(),
        inserted_at: Faker.DateTime.backward(Enum.random(1..30)),
        updated_at: Faker.DateTime.between(~N[2024-12-01T00:00:00Z], ~N[2025-03-01T23:59:59Z])
      }
    end

    # -------------------------------------------------------------------
    # MESSAGES
    # -------------------------------------------------------------------
    def message_factory do
      %Vyre.Messages.Message{
        content: Faker.Lorem.paragraph(),
        edited: Enum.random([false, true]),
        mentions_everyone: Enum.random([false, true]),
        inserted_at: Faker.DateTime.backward(Enum.random(1..30)),
        updated_at: Faker.DateTime.between(~N[2024-12-01T00:00:00Z], ~N[2025-03-01T23:59:59Z])
      }
    end

    # -------------------------------------------------------------------
    # PRIVATE MESSAGES
    # -------------------------------------------------------------------
    def private_message_factory do
      %Vyre.Messages.PrivateMessage{
        content: Faker.Lorem.paragraph(),
        read: Enum.random([true, false]),
        inserted_at: Faker.DateTime.backward(Enum.random(1..30)),
        updated_at: Faker.DateTime.between(~N[2024-12-01T00:00:00Z], ~N[2025-03-01T23:59:59Z])
      }
    end

    # -------------------------------------------------------------------
    # ROLES (for a server)
    # -------------------------------------------------------------------
    def role_factory do
      %Vyre.Roles.Role{
        name: Faker.Lorem.word(),
        color: Faker.Color.rgb_hex(),
        permissions: Faker.Lorem.words(3),
        server_id: nil,
        inserted_at: Faker.DateTime.backward(Enum.random(1..30)),
        updated_at: Faker.DateTime.between(~N[2024-12-01T00:00:00Z], ~N[2025-03-01T23:59:59Z])
      }
    end

    # -------------------------------------------------------------------
    # USER ROLES
    # -------------------------------------------------------------------
    def user_role_factory do
      %Vyre.Roles.UserRole{
        inserted_at: Faker.DateTime.backward(Enum.random(1..30)),
        updated_at: Faker.DateTime.between(~N[2024-12-01T00:00:00Z], ~N[2025-03-01T23:59:59Z])
      }
    end

    # -------------------------------------------------------------------
    # USER CHANNEL STATUSES
    # -------------------------------------------------------------------
    def user_channel_status_factory do
      %Vyre.Channels.UserChannelStatus{
        last_read_at: DateTime.utc_now() |> DateTime.add(-Enum.random(0..3) * 86400),
        mention_count: Enum.random(0..3)
      }
    end

    # -------------------------------------------------------------------
    # UNREAD MESSAGES STATUSES
    # -------------------------------------------------------------------
    def unread_channel_status_factory do
      %Vyre.Channels.UserChannelStatus{
        last_read_message_id: nil,
        last_read_at: nil,
        mention_count: Enum.random(1..5)
      }
    end

    def partial_channel_status_factory do
      %Vyre.Channels.UserChannelStatus{
        last_read_message_id: nil,
        last_read_at: DateTime.utc_now() |> DateTime.add(-86400 * Enum.random(1..5)),
        mention_count: Enum.random(0..3)
      }
    end
  end
end
