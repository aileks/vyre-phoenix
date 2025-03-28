defmodule VyreWeb.HomeLive do
  use VyreWeb, :live_view
  # alias VyreWeb.Components.Spinner

  def mount(_params, session, socket) do
    socket =
      socket
      |> assign(:page_title, "Vyre - Chat like a human")
      |> assign(:is_loading, false)
      |> assign(:is_authenticated, session["user_token"] != nil)

    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <div class="flex min-h-screen flex-col">
      <header class="bg-midnight-800 border-b border-gray-700 py-4">
        <div class="container mx-auto flex items-center justify-between px-4">
          <div class="flex items-center">
            <img
              src="/images/logo.png"
              alt="Vyre Logo"
              title="Vyre Logo"
              class="border-midnight-400 h-12 w-12 rounded-full border-2"
            />
          </div>

          <%= if @is_loading do %>
            <button
              disabled
              class="bg-midnight-700 text-cybertext-400 rounded-xs border border-gray-700 px-4 py-2"
            >
              <span class="flex items-center gap-2">
                <.spinner /> Loading...
              </span>
            </button>
          <% else %>
            <%= if !@is_authenticated do %>
              <.link
                navigate={~p"/users/login"}
                class="hover:text-verdant-400 transition-colors duration-200 ease-in-out cursor-pointer text-verdant-500 text-xl relative inline-block after:absolute after:bottom-[-2px] after:left-0 after:h-0.5 after:w-0 after:bg-verdant-400 after:transition-all after:duration-300 hover:after:w-full"
              >
                Login
              </.link>
            <% end %>
          <% end %>
        </div>
      </header>
      
    <!-- Hero Section -->
      <div class="container mx-auto max-w-6xl px-4 py-12">
        <div class="bg-midnight-800 overflow-hidden rounded-xs border border-gray-700 shadow-lg">
          <div class="bg-midnight-800 flex items-center border-b border-gray-700 px-4 py-2">
            <div class="mr-4 flex space-x-2">
              <div class="h-3 w-3 rounded-full bg-red-500"></div>
              <div class="h-3 w-3 rounded-full bg-yellow-500"></div>
              <div class="h-3 w-3 rounded-full bg-green-500"></div>
            </div>
          </div>

          <div class="flex flex-col gap-8 p-8 md:flex-row">
            <div class="md:w-1/2">
              <h1 class="mb-6 font-mono text-4xl font-bold md:text-5xl">
                <span class="text-primary-400">Vyre</span>
                <p class="mt-4 mb-0 text-3xl">Chat like a human</p>
              </h1>

              <p class="text-cybertext-400 mb-6 font-mono text-lg">
                A modern chat-based social platform. Lightweight, customizable,
                and privacy-focused.
              </p>

              <div class="mb-8 flex flex-col gap-1 font-mono text-sm">
                <span class="italic">
                  Robust chat command system for common functions
                </span>
                <span class="text-gray-200">/join #SoMDiscussion</span>
                <span class="text-gray-200">/msg @user Hey there!</span>
                <span class="text-gray-200">/mute #channel </span>
              </div>

              <div class="mb-8 font-mono">
                <div class="mb-2 flex items-center gap-2">
                  <Heroicons.icon name="check-circle" class="text-success-500 h-4 w-4" />
                  <span>Open source</span>
                </div>

                <div class="mb-2 flex items-center gap-2">
                  <Heroicons.icon name="check-circle" class="text-success-500 h-4 w-4" />
                  <span>Fault-tolerant</span>
                </div>

                <div class="flex items-center gap-2">
                  <Heroicons.icon name="check-circle" class="text-success-500 h-4 w-4" />
                  <span>Minimal</span>
                </div>
              </div>

              <div class="flex flex-col gap-4 sm:flex-row">
                <%= if !@is_authenticated do %>
                  <.link
                    navigate={~p"/users/register"}
                    class="bg-primary-700 hover:bg-primary-600 border-primary-400 rounded-xs border px-3 py-2 text-center font-mono duration-200 ease-in-out transition-colors"
                  >
                    Get Started
                  </.link>
                <% else %>
                  <div class="border-electric-500 bg-electric-300/20 rounded-xs border px-3 py-2 text-center font-mono">
                    Thanks for pre-registering!
                  </div>
                <% end %>

                <.link
                  href="https://github.com/aileks/Vyre"
                  class="bg-midnight-800 hover:bg-midnight-700 text-electric-400 hover:text-electric-300 rounded-xs border border-gray-700 px-3 py-2 text-center font-mono duration-200 ease-in-out"
                >
                  Learn More
                </.link>
              </div>
            </div>

            <div class="bg-midnight-900 flex items-center justify-center rounded-xs border border-gray-700 md:w-1/2">
              <div class="flex w-full flex-col items-center p-6">
                <div class="mb-4 flex items-center gap-1 self-start">
                  <div class="status-indicator status-indicator-online"></div>
                  <span class="font-sans font-semibold">Project Collab </span>-
                  <span class="font-mono">#general</span>
                </div>
                
    <!-- Mock Chat Interface Preview -->
                <div class="chat-message mb-3">
                  <div class="user-name mb-1 text-xs">kai</div>
                  Hey, everyone. I finished that presentation, want me to send
                  it over?
                </div>

                <div class="chat-message mb-3">
                  <div class="text-primary-400 mb-1 text-xs">@you</div>
                  Perfect! Thanks for finishing it so quickly.
                </div>

                <div class="chat-message mb-3">
                  <div class="user-name text-xs">MrChristo</div>
                  Yes, please!
                </div>

                <div class="chat-message-system mt-2 self-center">
                  User <span class="user-name underline">local cryptid</span>{" "} has joined #general
                </div>
              </div>
            </div>
          </div>

          <div class="bg-midnight-800 border-t border-gray-700 p-4">
            <div class="text-cybertext-500 flex items-center font-mono">
              <div class="font-semibold">
                Estimated Launch: 2025/08/12
              </div>
              <div class="flex items-center">
                <span class="bg-primary-400 animate-blink ml-1 inline-block h-4 w-2"></span>
              </div>
            </div>
          </div>
        </div>
      </div>
      
    <!-- Features Section -->
      <div class="container mx-auto px-4 py-16">
        <h2 class="text-cybertext-200 mb-12 text-center font-mono text-2xl md:text-3xl">
          Key Features
        </h2>

        <div class="grid grid-cols-1 gap-6 md:grid-cols-3">
          <div class="bg-midnight-800 rounded-xs border border-gray-700 p-6 shadow-lg">
            <div class="text-electric-400 mb-3 font-mono text-lg">
              Command-Driven <br />
              <span class="text-sm italic">Coming Soon</span>
            </div>

            <p class="text-cybertext-400">
              Easily access a command list with{" "}
              <kbd class="text-gray-300">Ctrl+K</kbd> or by beginning a message
              with a slash (<kbd class="text-gray-300">/</kbd>).
            </p>
          </div>

          <div class="bg-midnight-800 rounded-xs border border-gray-700 p-6 shadow-lg">
            <div class="text-verdant-300 mb-3 font-mono text-lg">
              Self-Hostable <br />
              <span class="text-sm italic">Coming Soon</span>
            </div>

            <p class="text-cybertext-400">
              Run your own server or join existing networks. You control your
              data and privacy at all times.
            </p>
          </div>

          <div class="bg-midnight-800 rounded-xs border border-gray-700 p-6 shadow-lg">
            <div class="mb-3 font-mono text-lg text-pink-400">
              Easy On The Eyes
            </div>

            <p class="text-cybertext-400">
              Dark mode by default with customizable themes. Low-light friendly
              for late night coding sessions.
            </p>
          </div>
        </div>
      </div>

      <footer class="bg-midnight-800 mt-auto border-t border-gray-700 py-8">
        <div class="container mx-auto px-4">
          <div class="flex flex-col items-center justify-between md:flex-row">
            <div class="text-primary-400 mb-4 text-lg md:mb-0">
              &copy; 2025 Vyre
            </div>

            <div class="text-cybertext-400 flex gap-6">
              <.link
                href="https://github.com/aileks/Vyre"
                class="hover:text-glow hover:text-primary-400 duration-200 ease-in-out"
              >
                GitHub
              </.link>
            </div>
          </div>
        </div>
      </footer>
    </div>
    """
  end

  # We'll add the spinner component here
  def spinner(assigns) do
    ~H"""
    <div
      class="inline-block h-4 w-4 animate-spin rounded-full border-2 border-solid border-current border-r-transparent align-[-0.125em] motion-reduce:animate-[spin_1.5s_linear_infinite]"
      role="status"
    >
      <span class="!absolute !-m-px !h-px !w-px !overflow-hidden !border-0 !p-0 !whitespace-nowrap ![clip:rect(0,0,0,0)]">
        Loading...
      </span>
    </div>
    """
  end
end
