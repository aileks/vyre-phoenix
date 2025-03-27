defmodule VyreWeb.PrivateMessageLiveTest do
  use VyreWeb.ConnCase

  import Phoenix.LiveViewTest
  import Vyre.MessagesFixtures

  @create_attrs %{read: true, content: "some content"}
  @update_attrs %{read: false, content: "some updated content"}
  @invalid_attrs %{read: false, content: nil}

  defp create_private_message(_) do
    private_message = private_message_fixture()
    %{private_message: private_message}
  end

  describe "Index" do
    setup [:create_private_message]

    test "lists all private_messages", %{conn: conn, private_message: private_message} do
      {:ok, _index_live, html} = live(conn, ~p"/private_messages")

      assert html =~ "Listing Private messages"
      assert html =~ private_message.content
    end

    test "saves new private_message", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, ~p"/private_messages")

      assert index_live |> element("a", "New Private message") |> render_click() =~
               "New Private message"

      assert_patch(index_live, ~p"/private_messages/new")

      assert index_live
             |> form("#private_message-form", private_message: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#private_message-form", private_message: @create_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/private_messages")

      html = render(index_live)
      assert html =~ "Private message created successfully"
      assert html =~ "some content"
    end

    test "updates private_message in listing", %{conn: conn, private_message: private_message} do
      {:ok, index_live, _html} = live(conn, ~p"/private_messages")

      assert index_live |> element("#private_messages-#{private_message.id} a", "Edit") |> render_click() =~
               "Edit Private message"

      assert_patch(index_live, ~p"/private_messages/#{private_message}/edit")

      assert index_live
             |> form("#private_message-form", private_message: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#private_message-form", private_message: @update_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/private_messages")

      html = render(index_live)
      assert html =~ "Private message updated successfully"
      assert html =~ "some updated content"
    end

    test "deletes private_message in listing", %{conn: conn, private_message: private_message} do
      {:ok, index_live, _html} = live(conn, ~p"/private_messages")

      assert index_live |> element("#private_messages-#{private_message.id} a", "Delete") |> render_click()
      refute has_element?(index_live, "#private_messages-#{private_message.id}")
    end
  end

  describe "Show" do
    setup [:create_private_message]

    test "displays private_message", %{conn: conn, private_message: private_message} do
      {:ok, _show_live, html} = live(conn, ~p"/private_messages/#{private_message}")

      assert html =~ "Show Private message"
      assert html =~ private_message.content
    end

    test "updates private_message within modal", %{conn: conn, private_message: private_message} do
      {:ok, show_live, _html} = live(conn, ~p"/private_messages/#{private_message}")

      assert show_live |> element("a", "Edit") |> render_click() =~
               "Edit Private message"

      assert_patch(show_live, ~p"/private_messages/#{private_message}/show/edit")

      assert show_live
             |> form("#private_message-form", private_message: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert show_live
             |> form("#private_message-form", private_message: @update_attrs)
             |> render_submit()

      assert_patch(show_live, ~p"/private_messages/#{private_message}")

      html = render(show_live)
      assert html =~ "Private message updated successfully"
      assert html =~ "some updated content"
    end
  end
end
