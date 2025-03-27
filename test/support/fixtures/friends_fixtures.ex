defmodule Vyre.FriendsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Vyre.Friends` context.
  """

  @doc """
  Generate a friend.
  """
  def friend_fixture(attrs \\ %{}) do
    {:ok, friend} =
      attrs
      |> Enum.into(%{

      })
      |> Vyre.Friends.create_friend()

    friend
  end
end
