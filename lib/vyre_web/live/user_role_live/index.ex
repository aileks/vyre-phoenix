defmodule VyreWeb.UserRoleLive.Index do
  use VyreWeb, :live_view

  alias Vyre.Roles
  alias Vyre.Roles.UserRole

  @impl true
  def mount(_params, _session, socket) do
    {:ok, stream(socket, :user_roles, Roles.list_user_roles())}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit User role")
    |> assign(:user_role, Roles.get_user_role!(id))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New User role")
    |> assign(:user_role, %UserRole{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing User roles")
    |> assign(:user_role, nil)
  end

  @impl true
  def handle_info({VyreWeb.UserRoleLive.FormComponent, {:saved, user_role}}, socket) do
    {:noreply, stream_insert(socket, :user_roles, user_role)}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    user_role = Roles.get_user_role!(id)
    {:ok, _} = Roles.delete_user_role(user_role)

    {:noreply, stream_delete(socket, :user_roles, user_role)}
  end
end
