defmodule VyreWeb.ServerLive.FormComponent do
  use VyreWeb, :live_component

  alias Vyre.Servers

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        {@title}
        <:subtitle>Use this form to manage server records in your database.</:subtitle>
      </.header>

      <.simple_form
        for={@form}
        id="server-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.input field={@form[:name]} type="text" label="Name" />
        <.input field={@form[:invite]} type="text" label="Invite" />
        <.input field={@form[:description]} type="text" label="Description" />
        <.input field={@form[:icon_url]} type="text" label="Icon url" />
        <:actions>
          <.button phx-disable-with="Saving...">Save Server</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(%{server: server} = assigns, socket) do
    {:ok,
     socket
     |> assign(assigns)
     |> assign_new(:form, fn ->
       to_form(Servers.change_server(server))
     end)}
  end

  @impl true
  def handle_event("validate", %{"server" => server_params}, socket) do
    changeset = Servers.change_server(socket.assigns.server, server_params)
    {:noreply, assign(socket, form: to_form(changeset, action: :validate))}
  end

  def handle_event("save", %{"server" => server_params}, socket) do
    save_server(socket, socket.assigns.action, server_params)
  end

  defp save_server(socket, :edit, server_params) do
    case Servers.update_server(socket.assigns.server, server_params) do
      {:ok, server} ->
        notify_parent({:saved, server})

        {:noreply,
         socket
         |> put_flash(:info, "Server updated successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp save_server(socket, :new, server_params) do
    case Servers.create_server(server_params) do
      {:ok, server} ->
        notify_parent({:saved, server})

        {:noreply,
         socket
         |> put_flash(:info, "Server created successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end
