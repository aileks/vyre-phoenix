defmodule Vyre.MessagesFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Vyre.Messages` context.
  """

  @doc """
  Generate a message.
  """
  def message_fixture(attrs \\ %{}) do
    {:ok, message} =
      attrs
      |> Enum.into(%{
        content: "some content",
        edited: true,
        mentions_everyone: true
      })
      |> Vyre.Messages.create_message()

    message
  end

  @doc """
  Generate a private_message.
  """
  def private_message_fixture(attrs \\ %{}) do
    {:ok, private_message} =
      attrs
      |> Enum.into(%{
        content: "some content",
        read: true
      })
      |> Vyre.Messages.create_private_message()

    private_message
  end
end
