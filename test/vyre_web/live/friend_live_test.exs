defmodule VyreWeb.FriendLiveTest do
  use VyreWeb.ConnCase

  import Phoenix.LiveViewTest
  import Vyre.FriendsFixtures

  @create_attrs %{}
  @update_attrs %{}
  @invalid_attrs %{}

  defp create_friend(_) do
    friend = friend_fixture()
    %{friend: friend}
  end

  describe "Index" do
    setup [:create_friend]

    test "lists all friends", %{conn: conn} do
      {:ok, _index_live, html} = live(conn, ~p"/friends")

      assert html =~ "Listing Friends"
    end

    test "saves new friend", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, ~p"/friends")

      assert index_live |> element("a", "New Friend") |> render_click() =~
               "New Friend"

      assert_patch(index_live, ~p"/friends/new")

      assert index_live
             |> form("#friend-form", friend: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#friend-form", friend: @create_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/friends")

      html = render(index_live)
      assert html =~ "Friend created successfully"
    end

    test "updates friend in listing", %{conn: conn, friend: friend} do
      {:ok, index_live, _html} = live(conn, ~p"/friends")

      assert index_live |> element("#friends-#{friend.id} a", "Edit") |> render_click() =~
               "Edit Friend"

      assert_patch(index_live, ~p"/friends/#{friend}/edit")

      assert index_live
             |> form("#friend-form", friend: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#friend-form", friend: @update_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/friends")

      html = render(index_live)
      assert html =~ "Friend updated successfully"
    end

    test "deletes friend in listing", %{conn: conn, friend: friend} do
      {:ok, index_live, _html} = live(conn, ~p"/friends")

      assert index_live |> element("#friends-#{friend.id} a", "Delete") |> render_click()
      refute has_element?(index_live, "#friends-#{friend.id}")
    end
  end

  describe "Show" do
    setup [:create_friend]

    test "displays friend", %{conn: conn, friend: friend} do
      {:ok, _show_live, html} = live(conn, ~p"/friends/#{friend}")

      assert html =~ "Show Friend"
    end

    test "updates friend within modal", %{conn: conn, friend: friend} do
      {:ok, show_live, _html} = live(conn, ~p"/friends/#{friend}")

      assert show_live |> element("a", "Edit") |> render_click() =~
               "Edit Friend"

      assert_patch(show_live, ~p"/friends/#{friend}/show/edit")

      assert show_live
             |> form("#friend-form", friend: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert show_live
             |> form("#friend-form", friend: @update_attrs)
             |> render_submit()

      assert_patch(show_live, ~p"/friends/#{friend}")

      html = render(show_live)
      assert html =~ "Friend updated successfully"
    end
  end
end
