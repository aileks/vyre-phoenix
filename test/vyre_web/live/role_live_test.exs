defmodule VyreWeb.RoleLiveTest do
  use VyreWeb.ConnCase

  import Phoenix.LiveViewTest
  import Vyre.RolesFixtures

  @create_attrs %{name: "some name", position: 42, permissions: 42, color: "some color", hoist: true, mentionable: true}
  @update_attrs %{name: "some updated name", position: 43, permissions: 43, color: "some updated color", hoist: false, mentionable: false}
  @invalid_attrs %{name: nil, position: nil, permissions: nil, color: nil, hoist: false, mentionable: false}

  defp create_role(_) do
    role = role_fixture()
    %{role: role}
  end

  describe "Index" do
    setup [:create_role]

    test "lists all roles", %{conn: conn, role: role} do
      {:ok, _index_live, html} = live(conn, ~p"/roles")

      assert html =~ "Listing Roles"
      assert html =~ role.name
    end

    test "saves new role", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, ~p"/roles")

      assert index_live |> element("a", "New Role") |> render_click() =~
               "New Role"

      assert_patch(index_live, ~p"/roles/new")

      assert index_live
             |> form("#role-form", role: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#role-form", role: @create_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/roles")

      html = render(index_live)
      assert html =~ "Role created successfully"
      assert html =~ "some name"
    end

    test "updates role in listing", %{conn: conn, role: role} do
      {:ok, index_live, _html} = live(conn, ~p"/roles")

      assert index_live |> element("#roles-#{role.id} a", "Edit") |> render_click() =~
               "Edit Role"

      assert_patch(index_live, ~p"/roles/#{role}/edit")

      assert index_live
             |> form("#role-form", role: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#role-form", role: @update_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/roles")

      html = render(index_live)
      assert html =~ "Role updated successfully"
      assert html =~ "some updated name"
    end

    test "deletes role in listing", %{conn: conn, role: role} do
      {:ok, index_live, _html} = live(conn, ~p"/roles")

      assert index_live |> element("#roles-#{role.id} a", "Delete") |> render_click()
      refute has_element?(index_live, "#roles-#{role.id}")
    end
  end

  describe "Show" do
    setup [:create_role]

    test "displays role", %{conn: conn, role: role} do
      {:ok, _show_live, html} = live(conn, ~p"/roles/#{role}")

      assert html =~ "Show Role"
      assert html =~ role.name
    end

    test "updates role within modal", %{conn: conn, role: role} do
      {:ok, show_live, _html} = live(conn, ~p"/roles/#{role}")

      assert show_live |> element("a", "Edit") |> render_click() =~
               "Edit Role"

      assert_patch(show_live, ~p"/roles/#{role}/show/edit")

      assert show_live
             |> form("#role-form", role: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert show_live
             |> form("#role-form", role: @update_attrs)
             |> render_submit()

      assert_patch(show_live, ~p"/roles/#{role}")

      html = render(show_live)
      assert html =~ "Role updated successfully"
      assert html =~ "some updated name"
    end
  end
end
