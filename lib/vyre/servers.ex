defmodule Vyre.Servers do
  @moduledoc """
  The Servers context.
  """

  import Ecto.Query, warn: false
  alias Vyre.Repo

  alias Vyre.Servers.Server

  @doc """
  Returns the list of servers.

  ## Examples

      iex> list_servers()
      [%Server{}, ...]

  """
  def list_servers do
    Repo.all(Server)
  end

  @doc """
  Gets a single server.

  Raises `Ecto.NoResultsError` if the Server does not exist.

  ## Examples

      iex> get_server!(123)
      %Server{}

      iex> get_server!(456)
      ** (Ecto.NoResultsError)

  """
  def get_server!(id), do: Repo.get!(Server, id)

  @doc """
  Creates a server.

  ## Examples

      iex> create_server(%{field: value})
      {:ok, %Server{}}

      iex> create_server(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_server(attrs \\ %{}) do
    %Server{}
    |> Server.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a server.

  ## Examples

      iex> update_server(server, %{field: new_value})
      {:ok, %Server{}}

      iex> update_server(server, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_server(%Server{} = server, attrs) do
    server
    |> Server.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a server.

  ## Examples

      iex> delete_server(server)
      {:ok, %Server{}}

      iex> delete_server(server)
      {:error, %Ecto.Changeset{}}

  """
  def delete_server(%Server{} = server) do
    Repo.delete(server)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking server changes.

  ## Examples

      iex> change_server(server)
      %Ecto.Changeset{data: %Server{}}

  """
  def change_server(%Server{} = server, attrs \\ %{}) do
    Server.changeset(server, attrs)
  end

  alias Vyre.Servers.ServerMember

  @doc """
  Returns the list of server_members.

  ## Examples

      iex> list_server_members()
      [%ServerMember{}, ...]

  """
  def list_server_members(server_id) do
    Repo.all(from sm in ServerMember, where: sm.server_id == ^server_id)
  end

  @doc """
  Gets a single server_member.

  Raises `Ecto.NoResultsError` if the Server member does not exist.

  ## Examples

      iex> get_server_member!(123)
      %ServerMember{}

      iex> get_server_member!(456)
      ** (Ecto.NoResultsError)

  """
  def get_server_member!(id), do: Repo.get!(ServerMember, id)

  @doc """
  Creates a server_member.

  ## Examples

      iex> create_server_member(%{field: value})
      {:ok, %ServerMember{}}

      iex> create_server_member(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_server_member(attrs \\ %{}) do
    %ServerMember{}
    |> ServerMember.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a server_member.

  ## Examples

      iex> update_server_member(server_member, %{field: new_value})
      {:ok, %ServerMember{}}

      iex> update_server_member(server_member, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_server_member(%ServerMember{} = server_member, attrs) do
    server_member
    |> ServerMember.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a server_member.

  ## Examples

      iex> delete_server_member(server_member)
      {:ok, %ServerMember{}}

      iex> delete_server_member(server_member)
      {:error, %Ecto.Changeset{}}

  """
  def delete_server_member(%ServerMember{} = server_member) do
    Repo.delete(server_member)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking server_member changes.

  ## Examples

      iex> change_server_member(server_member)
      %Ecto.Changeset{data: %ServerMember{}}

  """
  def change_server_member(%ServerMember{} = server_member, attrs \\ %{}) do
    ServerMember.changeset(server_member, attrs)
  end
end
