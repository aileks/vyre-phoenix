defmodule VyreWeb.RoleLive.Index do
  use VyreWeb, :live_view

  alias Vyre.Roles
  alias Vyre.Roles.Role

  @impl true
  def mount(_params, _session, socket) do
    {:ok, stream(socket, :roles, Roles.list_roles())}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit Role")
    |> assign(:role, Roles.get_role!(id))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Role")
    |> assign(:role, %Role{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing Roles")
    |> assign(:role, nil)
  end

  @impl true
  def handle_info({VyreWeb.RoleLive.FormComponent, {:saved, role}}, socket) do
    {:noreply, stream_insert(socket, :roles, role)}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    role = Roles.get_role!(id)
    {:ok, _} = Roles.delete_role(role)

    {:noreply, stream_delete(socket, :roles, role)}
  end
end
