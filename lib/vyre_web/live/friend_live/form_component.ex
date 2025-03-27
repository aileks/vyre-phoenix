defmodule VyreWeb.FriendLive.FormComponent do
  use VyreWeb, :live_component

  alias Vyre.Friends

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        {@title}
        <:subtitle>Use this form to manage friend records in your database.</:subtitle>
      </.header>

      <.simple_form
        for={@form}
        id="friend-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >

        <:actions>
          <.button phx-disable-with="Saving...">Save Friend</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(%{friend: friend} = assigns, socket) do
    {:ok,
     socket
     |> assign(assigns)
     |> assign_new(:form, fn ->
       to_form(Friends.change_friend(friend))
     end)}
  end

  @impl true
  def handle_event("validate", %{"friend" => friend_params}, socket) do
    changeset = Friends.change_friend(socket.assigns.friend, friend_params)
    {:noreply, assign(socket, form: to_form(changeset, action: :validate))}
  end

  def handle_event("save", %{"friend" => friend_params}, socket) do
    save_friend(socket, socket.assigns.action, friend_params)
  end

  defp save_friend(socket, :edit, friend_params) do
    case Friends.update_friend(socket.assigns.friend, friend_params) do
      {:ok, friend} ->
        notify_parent({:saved, friend})

        {:noreply,
         socket
         |> put_flash(:info, "Friend updated successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp save_friend(socket, :new, friend_params) do
    case Friends.create_friend(friend_params) do
      {:ok, friend} ->
        notify_parent({:saved, friend})

        {:noreply,
         socket
         |> put_flash(:info, "Friend created successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end
