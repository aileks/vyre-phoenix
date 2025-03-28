defmodule VyreWeb.UserRegistrationLive do
  use VyreWeb, :live_view

  alias Vyre.Accounts
  alias Vyre.Accounts.User

  def render(assigns) do
    ~H"""
    <div class="flex min-h-screen items-center justify-center px-4 py-8 sm:px-6 lg:px-8">
      <div class="bg-midnight-700 shadow-midnight-900/50 w-full max-w-md rounded-xs border border-gray-700 p-5 shadow-lg sm:p-7">
        <.header class="mb-4 text-pink-500">
          Register
        </.header>

        <.simple_form
          for={@form}
          id="registration_form"
          phx-submit="save"
          phx-change="validate"
          phx-trigger-action={@trigger_submit}
          action={~p"/users/login?_action=registered"}
          method="post"
        >
          <.error :if={@check_errors}>
            Oops, something went wrong! Please check the errors below.
          </.error>

          <.input
            field={@form[:email]}
            type="email"
            label="Email"
            placeholder="user@domain.com"
            required
          />
          <.input
            field={@form[:username]}
            type="text"
            placeholder="user123"
            label="Username"
            required
          />
          <.input
            field={@form[:password]}
            type="password"
            label="Password"
            required
            placeholder="••••••••"
          />
          <.input
            field={@form[:password_confirmation]}
            type="password"
            label="Confirm Password"
            placeholder="••••••••"
            required
          />

          <:actions>
            <.button
              phx-disable-with="Creating account..."
              class="text-cybertext-100 mt-4 w-full rounded-xs border border-pink-400 bg-pink-600 px-4 py-2 transition-all duration-200 ease-in-out hover:cursor-pointer hover:bg-pink-500 focus:ring-2 focus:ring-pink-500/50 focus:outline-none disabled:opacity-70 sm:mt-6 sm:py-2.5"
            >
              Create Account
            </.button>
          </:actions>
        </.simple_form>

        <div class="mt-6 border-t border-gray-700 pt-4 text-center sm:mt-8 sm:pt-6">
          <span class="text-cybertext-500 text-sm sm:text-base">
            Already have an account?
          </span>

          <.link
            navigate={~p"/users/login"}
            class="text-verdant-400 hover:text-verdant-300 text-sm transition-colors duration-200 ease-in-out sm:text-base"
          >
            Log in here
          </.link>
        </div>
      </div>

      <.flash_group flash={@flash} />
    </div>
    """
  end

  def mount(_params, _session, socket) do
    changeset = Accounts.change_user_registration(%User{})

    socket =
      socket
      |> assign(trigger_submit: false, check_errors: false)
      |> assign_form(changeset)

    {:ok, socket, temporary_assigns: [form: nil]}
  end

  def handle_event("save", %{"user" => user_params}, socket) do
    case Accounts.register_user(user_params) do
      {:ok, user} ->
        {:ok, _} =
          Accounts.deliver_user_confirmation_instructions(
            user,
            &url(~p"/users/confirm/#{&1}")
          )

        changeset = Accounts.change_user_registration(user)
        {:noreply, socket |> assign(trigger_submit: true) |> assign_form(changeset)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, socket |> assign(check_errors: true) |> assign_form(changeset)}
    end
  end

  def handle_event("validate", %{"user" => user_params}, socket) do
    changeset = Accounts.change_user_registration(%User{}, user_params)
    {:noreply, assign_form(socket, Map.put(changeset, :action, :validate))}
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    form = to_form(changeset, as: "user")

    if changeset.valid? do
      assign(socket, form: form, check_errors: false)
    else
      assign(socket, form: form)
    end
  end
end
