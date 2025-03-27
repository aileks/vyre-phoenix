defmodule Vyre.ChannelsTest do
  use Vyre.DataCase

  alias Vyre.Channels

  describe "channels" do
    alias Vyre.Channels.Channel

    import Vyre.ChannelsFixtures

    @invalid_attrs %{name: nil, type: nil, description: nil, topic: nil}

    test "list_channels/0 returns all channels" do
      channel = channel_fixture()
      assert Channels.list_channels() == [channel]
    end

    test "get_channel!/1 returns the channel with given id" do
      channel = channel_fixture()
      assert Channels.get_channel!(channel.id) == channel
    end

    test "create_channel/1 with valid data creates a channel" do
      valid_attrs = %{name: "some name", type: "some type", description: "some description", topic: "some topic"}

      assert {:ok, %Channel{} = channel} = Channels.create_channel(valid_attrs)
      assert channel.name == "some name"
      assert channel.type == "some type"
      assert channel.description == "some description"
      assert channel.topic == "some topic"
    end

    test "create_channel/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Channels.create_channel(@invalid_attrs)
    end

    test "update_channel/2 with valid data updates the channel" do
      channel = channel_fixture()
      update_attrs = %{name: "some updated name", type: "some updated type", description: "some updated description", topic: "some updated topic"}

      assert {:ok, %Channel{} = channel} = Channels.update_channel(channel, update_attrs)
      assert channel.name == "some updated name"
      assert channel.type == "some updated type"
      assert channel.description == "some updated description"
      assert channel.topic == "some updated topic"
    end

    test "update_channel/2 with invalid data returns error changeset" do
      channel = channel_fixture()
      assert {:error, %Ecto.Changeset{}} = Channels.update_channel(channel, @invalid_attrs)
      assert channel == Channels.get_channel!(channel.id)
    end

    test "delete_channel/1 deletes the channel" do
      channel = channel_fixture()
      assert {:ok, %Channel{}} = Channels.delete_channel(channel)
      assert_raise Ecto.NoResultsError, fn -> Channels.get_channel!(channel.id) end
    end

    test "change_channel/1 returns a channel changeset" do
      channel = channel_fixture()
      assert %Ecto.Changeset{} = Channels.change_channel(channel)
    end
  end
end
