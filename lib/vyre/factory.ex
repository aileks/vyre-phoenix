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
        user_id: build(:user).id,
        friend_id: build(:user).id,
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
        owner_id: build(:user).id,
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
        user_id: build(:user).id,
        server_id: build(:server).id,
        nickname: Enum.random([nil, Faker.Superhero.name(), Faker.Internet.user_name()]),
        inserted_at: Faker.DateTime.backward(Enum.random(1..30))
      }
    end

    # -------------------------------------------------------------------
    # CHANNELS
    # -------------------------------------------------------------------
    def channel_factory do
      %Vyre.Channels.Channel{
        server_id: build(:server).id,
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
        user_id: build(:user).id,
        channel_id: build(:channel).id,
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
        sender_id: build(:user).id,
        receiver_id: build(:user).id,
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
        server_id: build(:server).id,
        inserted_at: Faker.DateTime.backward(Enum.random(1..30)),
        updated_at: Faker.DateTime.between(~N[2024-12-01T00:00:00Z], ~N[2025-03-01T23:59:59Z])
      }
    end

    # -------------------------------------------------------------------
    # USER ROLES
    # -------------------------------------------------------------------
    def user_role_factory do
      %Vyre.Roles.UserRole{
        user_id: build(:user).id,
        role_id: build(:role).id,
        inserted_at: Faker.DateTime.backward(Enum.random(1..30)),
        updated_at: Faker.DateTime.between(~N[2024-12-01T00:00:00Z], ~N[2025-03-01T23:59:59Z])
      }
    end
  end
end
