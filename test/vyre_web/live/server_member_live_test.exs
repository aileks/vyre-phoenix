defmodule VyreWeb.ServerMemberLiveTest do
  use VyreWeb.ConnCase

  import Phoenix.LiveViewTest
  import Vyre.ServersFixtures

  @create_attrs %{nickname: "some nickname"}
  @update_attrs %{nickname: "some updated nickname"}
  @invalid_attrs %{nickname: nil}

  defp create_server_member(_) do
    server_member = server_member_fixture()
    %{server_member: server_member}
  end

  describe "Index" do
    setup [:create_server_member]

    test "lists all server_members", %{conn: conn, server_member: server_member} do
      {:ok, _index_live, html} = live(conn, ~p"/server_members")

      assert html =~ "Listing Server members"
      assert html =~ server_member.nickname
    end

    test "saves new server_member", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, ~p"/server_members")

      assert index_live |> element("a", "New Server member") |> render_click() =~
               "New Server member"

      assert_patch(index_live, ~p"/server_members/new")

      assert index_live
             |> form("#server_member-form", server_member: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#server_member-form", server_member: @create_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/server_members")

      html = render(index_live)
      assert html =~ "Server member created successfully"
      assert html =~ "some nickname"
    end

    test "updates server_member in listing", %{conn: conn, server_member: server_member} do
      {:ok, index_live, _html} = live(conn, ~p"/server_members")

      assert index_live |> element("#server_members-#{server_member.id} a", "Edit") |> render_click() =~
               "Edit Server member"

      assert_patch(index_live, ~p"/server_members/#{server_member}/edit")

      assert index_live
             |> form("#server_member-form", server_member: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#server_member-form", server_member: @update_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/server_members")

      html = render(index_live)
      assert html =~ "Server member updated successfully"
      assert html =~ "some updated nickname"
    end

    test "deletes server_member in listing", %{conn: conn, server_member: server_member} do
      {:ok, index_live, _html} = live(conn, ~p"/server_members")

      assert index_live |> element("#server_members-#{server_member.id} a", "Delete") |> render_click()
      refute has_element?(index_live, "#server_members-#{server_member.id}")
    end
  end

  describe "Show" do
    setup [:create_server_member]

    test "displays server_member", %{conn: conn, server_member: server_member} do
      {:ok, _show_live, html} = live(conn, ~p"/server_members/#{server_member}")

      assert html =~ "Show Server member"
      assert html =~ server_member.nickname
    end

    test "updates server_member within modal", %{conn: conn, server_member: server_member} do
      {:ok, show_live, _html} = live(conn, ~p"/server_members/#{server_member}")

      assert show_live |> element("a", "Edit") |> render_click() =~
               "Edit Server member"

      assert_patch(show_live, ~p"/server_members/#{server_member}/show/edit")

      assert show_live
             |> form("#server_member-form", server_member: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert show_live
             |> form("#server_member-form", server_member: @update_attrs)
             |> render_submit()

      assert_patch(show_live, ~p"/server_members/#{server_member}")

      html = render(show_live)
      assert html =~ "Server member updated successfully"
      assert html =~ "some updated nickname"
    end
  end
end
