defmodule Vyre.Friends do
  @moduledoc """
  The Friends context.
  """

  import Ecto.Query, warn: false
  alias Vyre.Repo

  alias Vyre.Friends.Friend

  @doc """
  Returns the list of friends.

  ## Examples

      iex> list_friends()
      [%Friend{}, ...]

  """
  def list_friends do
    Repo.all(Friend)
  end

  @doc """
  Gets a single friend.

  Raises `Ecto.NoResultsError` if the Friend does not exist.

  ## Examples

      iex> get_friend!(123)
      %Friend{}

      iex> get_friend!(456)
      ** (Ecto.NoResultsError)

  """
  def get_friend!(id), do: Repo.get!(Friend, id)

  @doc """
  Creates a friend.

  ## Examples

      iex> create_friend(%{field: value})
      {:ok, %Friend{}}

      iex> create_friend(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_friend(attrs \\ %{}) do
    %Friend{}
    |> Friend.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a friend.

  ## Examples

      iex> update_friend(friend, %{field: new_value})
      {:ok, %Friend{}}

      iex> update_friend(friend, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_friend(%Friend{} = friend, attrs) do
    friend
    |> Friend.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a friend.

  ## Examples

      iex> delete_friend(friend)
      {:ok, %Friend{}}

      iex> delete_friend(friend)
      {:error, %Ecto.Changeset{}}

  """
  def delete_friend(%Friend{} = friend) do
    Repo.delete(friend)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking friend changes.

  ## Examples

      iex> change_friend(friend)
      %Ecto.Changeset{data: %Friend{}}

  """
  def change_friend(%Friend{} = friend, attrs \\ %{}) do
    Friend.changeset(friend, attrs)
  end
end
