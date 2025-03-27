defmodule Vyre.RolesTest do
  use Vyre.DataCase

  alias Vyre.Roles

  describe "roles" do
    alias Vyre.Roles.Role

    import Vyre.RolesFixtures

    @invalid_attrs %{name: nil, position: nil, permissions: nil, color: nil, hoist: nil, mentionable: nil}

    test "list_roles/0 returns all roles" do
      role = role_fixture()
      assert Roles.list_roles() == [role]
    end

    test "get_role!/1 returns the role with given id" do
      role = role_fixture()
      assert Roles.get_role!(role.id) == role
    end

    test "create_role/1 with valid data creates a role" do
      valid_attrs = %{name: "some name", position: 42, permissions: 42, color: "some color", hoist: true, mentionable: true}

      assert {:ok, %Role{} = role} = Roles.create_role(valid_attrs)
      assert role.name == "some name"
      assert role.position == 42
      assert role.permissions == 42
      assert role.color == "some color"
      assert role.hoist == true
      assert role.mentionable == true
    end

    test "create_role/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Roles.create_role(@invalid_attrs)
    end

    test "update_role/2 with valid data updates the role" do
      role = role_fixture()
      update_attrs = %{name: "some updated name", position: 43, permissions: 43, color: "some updated color", hoist: false, mentionable: false}

      assert {:ok, %Role{} = role} = Roles.update_role(role, update_attrs)
      assert role.name == "some updated name"
      assert role.position == 43
      assert role.permissions == 43
      assert role.color == "some updated color"
      assert role.hoist == false
      assert role.mentionable == false
    end

    test "update_role/2 with invalid data returns error changeset" do
      role = role_fixture()
      assert {:error, %Ecto.Changeset{}} = Roles.update_role(role, @invalid_attrs)
      assert role == Roles.get_role!(role.id)
    end

    test "delete_role/1 deletes the role" do
      role = role_fixture()
      assert {:ok, %Role{}} = Roles.delete_role(role)
      assert_raise Ecto.NoResultsError, fn -> Roles.get_role!(role.id) end
    end

    test "change_role/1 returns a role changeset" do
      role = role_fixture()
      assert %Ecto.Changeset{} = Roles.change_role(role)
    end
  end

  describe "user_roles" do
    alias Vyre.Roles.UserRole

    import Vyre.RolesFixtures

    @invalid_attrs %{}

    test "list_user_roles/0 returns all user_roles" do
      user_role = user_role_fixture()
      assert Roles.list_user_roles() == [user_role]
    end

    test "get_user_role!/1 returns the user_role with given id" do
      user_role = user_role_fixture()
      assert Roles.get_user_role!(user_role.id) == user_role
    end

    test "create_user_role/1 with valid data creates a user_role" do
      valid_attrs = %{}

      assert {:ok, %UserRole{} = user_role} = Roles.create_user_role(valid_attrs)
    end

    test "create_user_role/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Roles.create_user_role(@invalid_attrs)
    end

    test "update_user_role/2 with valid data updates the user_role" do
      user_role = user_role_fixture()
      update_attrs = %{}

      assert {:ok, %UserRole{} = user_role} = Roles.update_user_role(user_role, update_attrs)
    end

    test "update_user_role/2 with invalid data returns error changeset" do
      user_role = user_role_fixture()
      assert {:error, %Ecto.Changeset{}} = Roles.update_user_role(user_role, @invalid_attrs)
      assert user_role == Roles.get_user_role!(user_role.id)
    end

    test "delete_user_role/1 deletes the user_role" do
      user_role = user_role_fixture()
      assert {:ok, %UserRole{}} = Roles.delete_user_role(user_role)
      assert_raise Ecto.NoResultsError, fn -> Roles.get_user_role!(user_role.id) end
    end

    test "change_user_role/1 returns a user_role changeset" do
      user_role = user_role_fixture()
      assert %Ecto.Changeset{} = Roles.change_user_role(user_role)
    end
  end
end
