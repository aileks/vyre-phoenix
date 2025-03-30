defmodule VyreWeb.UserLoginLive do
  use VyreWeb, :live_view

  def render(assigns) do
    ~H"""
    <div class="flex min-h-screen items-center justify-center px-4 py-8 sm:px-6 lg:px-8">
      <div class="bg-midnight-700 shadow-midnight-900/50 w-full max-w-md rounded-xs border border-gray-700 p-5 shadow-lg sm:p-7">
        <.header class="text-verdant-400 mb-4">
          Log In
        </.header>

        <.simple_form for={@form} id="login_form" action={~p"/users/login"} phx-update="ignore">
          <.input
            field={@form[:email]}
            type="email"
            label="Email"
            placeholder="user@domain.com"
            required
          />

          <.input
            field={@form[:password]}
            type="password"
            label="Password"
            placeholder="••••••••"
            required
          />

          <:actions>
            <.input field={@form[:remember_me]} type="checkbox" label="Keep me logged in" />

            <.link
              href={~p"/users/reset"}
              class="text-sm hover:text-electric-500 duration-200 ease-in-out transition-colors text-electric-600 font-semibold"
            >
              Forgot your password?
            </.link>
          </:actions>

          <:actions>
            <.button
              phx-disable-with="Logging in..."
              class="border-verdant-400 bg-verdant-600 hover:bg-verdant-500 focus:ring-verdant-500/50 w-full rounded-xs border transition-colors duration-200 ease-in-out cursor-pointer focus:ring-2 focus:outline-none disabled:opacity-70 sm:py-2.5"
            >
              Log In <span aria-hidden="true">→</span>
            </.button>
          </:actions>
        </.simple_form>

        <div class="mt-6 border-t border-gray-700 pt-4 text-center sm:mt-8 sm:pt-6">
          <span class="text-cybertext-600 text-sm sm:text-base">
            Need an account?
          </span>
          <.link
            navigate={~p"/users/register"}
            class="text-sm text-pink-500 transition-colors duration-200 ease-in-out hover:text-pink-400 sm:text-base"
          >
            Register here
          </.link>
        </div>
      </div>
    </div>
    """
  end

  def mount(_params, _session, socket) do
    email = Phoenix.Flash.get(socket.assigns.flash, :email)
    form = to_form(%{"email" => email}, as: "user")
    {:ok, assign(socket, form: form), temporary_assigns: [form: form]}
  end
end
