defmodule VyreWeb.UserRoleLiveTest do
  use VyreWeb.ConnCase

  import Phoenix.LiveViewTest
  import Vyre.RolesFixtures

  @create_attrs %{}
  @update_attrs %{}
  @invalid_attrs %{}

  defp create_user_role(_) do
    user_role = user_role_fixture()
    %{user_role: user_role}
  end

  describe "Index" do
    setup [:create_user_role]

    test "lists all user_roles", %{conn: conn} do
      {:ok, _index_live, html} = live(conn, ~p"/user_roles")

      assert html =~ "Listing User roles"
    end

    test "saves new user_role", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, ~p"/user_roles")

      assert index_live |> element("a", "New User role") |> render_click() =~
               "New User role"

      assert_patch(index_live, ~p"/user_roles/new")

      assert index_live
             |> form("#user_role-form", user_role: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#user_role-form", user_role: @create_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/user_roles")

      html = render(index_live)
      assert html =~ "User role created successfully"
    end

    test "updates user_role in listing", %{conn: conn, user_role: user_role} do
      {:ok, index_live, _html} = live(conn, ~p"/user_roles")

      assert index_live |> element("#user_roles-#{user_role.id} a", "Edit") |> render_click() =~
               "Edit User role"

      assert_patch(index_live, ~p"/user_roles/#{user_role}/edit")

      assert index_live
             |> form("#user_role-form", user_role: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#user_role-form", user_role: @update_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/user_roles")

      html = render(index_live)
      assert html =~ "User role updated successfully"
    end

    test "deletes user_role in listing", %{conn: conn, user_role: user_role} do
      {:ok, index_live, _html} = live(conn, ~p"/user_roles")

      assert index_live |> element("#user_roles-#{user_role.id} a", "Delete") |> render_click()
      refute has_element?(index_live, "#user_roles-#{user_role.id}")
    end
  end

  describe "Show" do
    setup [:create_user_role]

    test "displays user_role", %{conn: conn, user_role: user_role} do
      {:ok, _show_live, html} = live(conn, ~p"/user_roles/#{user_role}")

      assert html =~ "Show User role"
    end

    test "updates user_role within modal", %{conn: conn, user_role: user_role} do
      {:ok, show_live, _html} = live(conn, ~p"/user_roles/#{user_role}")

      assert show_live |> element("a", "Edit") |> render_click() =~
               "Edit User role"

      assert_patch(show_live, ~p"/user_roles/#{user_role}/show/edit")

      assert show_live
             |> form("#user_role-form", user_role: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert show_live
             |> form("#user_role-form", user_role: @update_attrs)
             |> render_submit()

      assert_patch(show_live, ~p"/user_roles/#{user_role}")

      html = render(show_live)
      assert html =~ "User role updated successfully"
    end
  end
end
