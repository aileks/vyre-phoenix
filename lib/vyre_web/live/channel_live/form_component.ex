defmodule VyreWeb.ChannelLive.FormComponent do
  use VyreWeb, :live_component

  alias Vyre.Channels

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        {@title}
        <:subtitle>Use this form to manage channel records in your database.</:subtitle>
      </.header>

      <.simple_form
        for={@form}
        id="channel-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.input field={@form[:name]} type="text" label="Name" />
        <.input field={@form[:topic]} type="text" label="Topic" />
        <.input field={@form[:description]} type="text" label="Description" />
        <.input field={@form[:type]} type="text" label="Type" />
        <:actions>
          <.button phx-disable-with="Saving...">Save Channel</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(%{channel: channel} = assigns, socket) do
    {:ok,
     socket
     |> assign(assigns)
     |> assign_new(:form, fn ->
       to_form(Channels.change_channel(channel))
     end)}
  end

  @impl true
  def handle_event("validate", %{"channel" => channel_params}, socket) do
    changeset = Channels.change_channel(socket.assigns.channel, channel_params)
    {:noreply, assign(socket, form: to_form(changeset, action: :validate))}
  end

  def handle_event("save", %{"channel" => channel_params}, socket) do
    save_channel(socket, socket.assigns.action, channel_params)
  end

  defp save_channel(socket, :edit, channel_params) do
    case Channels.update_channel(socket.assigns.channel, channel_params) do
      {:ok, channel} ->
        notify_parent({:saved, channel})

        {:noreply,
         socket
         |> put_flash(:info, "Channel updated successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp save_channel(socket, :new, channel_params) do
    case Channels.create_channel(channel_params) do
      {:ok, channel} ->
        notify_parent({:saved, channel})

        {:noreply,
         socket
         |> put_flash(:info, "Channel created successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end
