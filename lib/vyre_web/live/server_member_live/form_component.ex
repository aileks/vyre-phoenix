defmodule VyreWeb.ServerMemberLive.FormComponent do
  use VyreWeb, :live_component

  alias Vyre.Servers

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        {@title}
        <:subtitle>Use this form to manage server_member records in your database.</:subtitle>
      </.header>

      <.simple_form
        for={@form}
        id="server_member-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.input field={@form[:nickname]} type="text" label="Nickname" />
        <:actions>
          <.button phx-disable-with="Saving...">Save Server member</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(%{server_member: server_member} = assigns, socket) do
    {:ok,
     socket
     |> assign(assigns)
     |> assign_new(:form, fn ->
       to_form(Servers.change_server_member(server_member))
     end)}
  end

  @impl true
  def handle_event("validate", %{"server_member" => server_member_params}, socket) do
    changeset = Servers.change_server_member(socket.assigns.server_member, server_member_params)
    {:noreply, assign(socket, form: to_form(changeset, action: :validate))}
  end

  def handle_event("save", %{"server_member" => server_member_params}, socket) do
    save_server_member(socket, socket.assigns.action, server_member_params)
  end

  defp save_server_member(socket, :edit, server_member_params) do
    case Servers.update_server_member(socket.assigns.server_member, server_member_params) do
      {:ok, server_member} ->
        notify_parent({:saved, server_member})

        {:noreply,
         socket
         |> put_flash(:info, "Server member updated successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp save_server_member(socket, :new, server_member_params) do
    case Servers.create_server_member(server_member_params) do
      {:ok, server_member} ->
        notify_parent({:saved, server_member})

        {:noreply,
         socket
         |> put_flash(:info, "Server member created successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end
