defmodule VyreWeb.UserRoleLive.FormComponent do
  use VyreWeb, :live_component

  alias Vyre.Roles

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        {@title}
        <:subtitle>Use this form to manage user_role records in your database.</:subtitle>
      </.header>

      <.simple_form
        for={@form}
        id="user_role-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >

        <:actions>
          <.button phx-disable-with="Saving...">Save User role</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(%{user_role: user_role} = assigns, socket) do
    {:ok,
     socket
     |> assign(assigns)
     |> assign_new(:form, fn ->
       to_form(Roles.change_user_role(user_role))
     end)}
  end

  @impl true
  def handle_event("validate", %{"user_role" => user_role_params}, socket) do
    changeset = Roles.change_user_role(socket.assigns.user_role, user_role_params)
    {:noreply, assign(socket, form: to_form(changeset, action: :validate))}
  end

  def handle_event("save", %{"user_role" => user_role_params}, socket) do
    save_user_role(socket, socket.assigns.action, user_role_params)
  end

  defp save_user_role(socket, :edit, user_role_params) do
    case Roles.update_user_role(socket.assigns.user_role, user_role_params) do
      {:ok, user_role} ->
        notify_parent({:saved, user_role})

        {:noreply,
         socket
         |> put_flash(:info, "User role updated successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp save_user_role(socket, :new, user_role_params) do
    case Roles.create_user_role(user_role_params) do
      {:ok, user_role} ->
        notify_parent({:saved, user_role})

        {:noreply,
         socket
         |> put_flash(:info, "User role created successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end
