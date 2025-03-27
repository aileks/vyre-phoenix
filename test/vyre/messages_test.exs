defmodule Vyre.MessagesTest do
  use Vyre.DataCase

  alias Vyre.Messages

  describe "messages" do
    alias Vyre.Messages.Message

    import Vyre.MessagesFixtures

    @invalid_attrs %{content: nil, edited: nil, mentions_everyone: nil}

    test "list_messages/0 returns all messages" do
      message = message_fixture()
      assert Messages.list_messages() == [message]
    end

    test "get_message!/1 returns the message with given id" do
      message = message_fixture()
      assert Messages.get_message!(message.id) == message
    end

    test "create_message/1 with valid data creates a message" do
      valid_attrs = %{content: "some content", edited: true, mentions_everyone: true}

      assert {:ok, %Message{} = message} = Messages.create_message(valid_attrs)
      assert message.content == "some content"
      assert message.edited == true
      assert message.mentions_everyone == true
    end

    test "create_message/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Messages.create_message(@invalid_attrs)
    end

    test "update_message/2 with valid data updates the message" do
      message = message_fixture()
      update_attrs = %{content: "some updated content", edited: false, mentions_everyone: false}

      assert {:ok, %Message{} = message} = Messages.update_message(message, update_attrs)
      assert message.content == "some updated content"
      assert message.edited == false
      assert message.mentions_everyone == false
    end

    test "update_message/2 with invalid data returns error changeset" do
      message = message_fixture()
      assert {:error, %Ecto.Changeset{}} = Messages.update_message(message, @invalid_attrs)
      assert message == Messages.get_message!(message.id)
    end

    test "delete_message/1 deletes the message" do
      message = message_fixture()
      assert {:ok, %Message{}} = Messages.delete_message(message)
      assert_raise Ecto.NoResultsError, fn -> Messages.get_message!(message.id) end
    end

    test "change_message/1 returns a message changeset" do
      message = message_fixture()
      assert %Ecto.Changeset{} = Messages.change_message(message)
    end
  end

  describe "private_messages" do
    alias Vyre.Messages.PrivateMessage

    import Vyre.MessagesFixtures

    @invalid_attrs %{read: nil, content: nil}

    test "list_private_messages/0 returns all private_messages" do
      private_message = private_message_fixture()
      assert Messages.list_private_messages() == [private_message]
    end

    test "get_private_message!/1 returns the private_message with given id" do
      private_message = private_message_fixture()
      assert Messages.get_private_message!(private_message.id) == private_message
    end

    test "create_private_message/1 with valid data creates a private_message" do
      valid_attrs = %{read: true, content: "some content"}

      assert {:ok, %PrivateMessage{} = private_message} = Messages.create_private_message(valid_attrs)
      assert private_message.read == true
      assert private_message.content == "some content"
    end

    test "create_private_message/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Messages.create_private_message(@invalid_attrs)
    end

    test "update_private_message/2 with valid data updates the private_message" do
      private_message = private_message_fixture()
      update_attrs = %{read: false, content: "some updated content"}

      assert {:ok, %PrivateMessage{} = private_message} = Messages.update_private_message(private_message, update_attrs)
      assert private_message.read == false
      assert private_message.content == "some updated content"
    end

    test "update_private_message/2 with invalid data returns error changeset" do
      private_message = private_message_fixture()
      assert {:error, %Ecto.Changeset{}} = Messages.update_private_message(private_message, @invalid_attrs)
      assert private_message == Messages.get_private_message!(private_message.id)
    end

    test "delete_private_message/1 deletes the private_message" do
      private_message = private_message_fixture()
      assert {:ok, %PrivateMessage{}} = Messages.delete_private_message(private_message)
      assert_raise Ecto.NoResultsError, fn -> Messages.get_private_message!(private_message.id) end
    end

    test "change_private_message/1 returns a private_message changeset" do
      private_message = private_message_fixture()
      assert %Ecto.Changeset{} = Messages.change_private_message(private_message)
    end
  end
end
