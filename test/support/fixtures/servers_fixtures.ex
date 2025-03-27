defmodule Vyre.ServersFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Vyre.Servers` context.
  """

  @doc """
  Generate a server.
  """
  def server_fixture(attrs \\ %{}) do
    {:ok, server} =
      attrs
      |> Enum.into(%{
        description: "some description",
        icon_url: "some icon_url",
        invite: "some invite",
        name: "some name"
      })
      |> Vyre.Servers.create_server()

    server
  end

  @doc """
  Generate a server_member.
  """
  def server_member_fixture(attrs \\ %{}) do
    {:ok, server_member} =
      attrs
      |> Enum.into(%{
        nickname: "some nickname"
      })
      |> Vyre.Servers.create_server_member()

    server_member
  end
end
