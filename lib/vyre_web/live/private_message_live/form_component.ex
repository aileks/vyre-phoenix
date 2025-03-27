defmodule VyreWeb.PrivateMessageLive.FormComponent do
  use VyreWeb, :live_component

  alias Vyre.Messages

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        {@title}
        <:subtitle>Use this form to manage private_message records in your database.</:subtitle>
      </.header>

      <.simple_form
        for={@form}
        id="private_message-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.input field={@form[:content]} type="text" label="Content" />
        <.input field={@form[:read]} type="checkbox" label="Read" />
        <:actions>
          <.button phx-disable-with="Saving...">Save Private message</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(%{private_message: private_message} = assigns, socket) do
    {:ok,
     socket
     |> assign(assigns)
     |> assign_new(:form, fn ->
       to_form(Messages.change_private_message(private_message))
     end)}
  end

  @impl true
  def handle_event("validate", %{"private_message" => private_message_params}, socket) do
    changeset = Messages.change_private_message(socket.assigns.private_message, private_message_params)
    {:noreply, assign(socket, form: to_form(changeset, action: :validate))}
  end

  def handle_event("save", %{"private_message" => private_message_params}, socket) do
    save_private_message(socket, socket.assigns.action, private_message_params)
  end

  defp save_private_message(socket, :edit, private_message_params) do
    case Messages.update_private_message(socket.assigns.private_message, private_message_params) do
      {:ok, private_message} ->
        notify_parent({:saved, private_message})

        {:noreply,
         socket
         |> put_flash(:info, "Private message updated successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp save_private_message(socket, :new, private_message_params) do
    case Messages.create_private_message(private_message_params) do
      {:ok, private_message} ->
        notify_parent({:saved, private_message})

        {:noreply,
         socket
         |> put_flash(:info, "Private message created successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end
