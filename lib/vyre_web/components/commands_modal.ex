defmodule VyreWeb.Components.CommandsModal do
  use VyreWeb, :live_component

  def mount(socket) do
    commands = [
      %{
        name: "join",
        description: "Join a channel",
        usage: "/join #channel",
        example: "/join #cyberpunk",
        category: "navigation"
      },
      %{
        name: "leave",
        description: "Leave current channel",
        usage: "/leave",
        example: "/leave",
        category: "navigation"
      },
      %{
        name: "nick",
        description: "Change your nickname",
        usage: "/nick new_name",
        example: "/nick CyberHacker42",
        category: "profile"
      },
      %{
        name: "msg",
        description: "Send private message",
        usage: "/msg @user message",
        example: "/msg @kai Hey, how's it going?",
        category: "messaging"
      },
      %{
        name: "clear",
        description: "Clear chat history",
        usage: "/clear",
        example: "/clear",
        category: "utility"
      },
      %{
        name: "help",
        description: "Show help for commands",
        usage: "/help [command]",
        example: "/help join",
        category: "utility"
      },
      %{
        name: "add",
        description: "Add a friend",
        usage: "/add username",
        example: "/add cyberpunk42",
        category: "social"
      },
      %{
        name: "block",
        description: "Block a user",
        usage: "/block username",
        example: "/block spammer123",
        category: "moderation"
      },
      %{
        name: "unblock",
        description: "Unblock a user",
        usage: "/unblock username",
        example: "/unblock formerSpammer",
        category: "moderation"
      },
      %{
        name: "alias",
        description: "Create command alias",
        usage: "/alias name command",
        example: "/alias j /join",
        category: "utility"
      },
      %{
        name: "status",
        description: "Set your status",
        usage: "/status [online|away|busy|invisible]",
        example: "/status busy",
        category: "profile"
      },
      %{
        name: "mute",
        description: "Mute a channel",
        usage: "/mute #channel",
        example: "/mute #general",
        category: "moderation"
      },
      %{
        name: "unmute",
        description: "Unmute a channel",
        usage: "/unmute #channel",
        example: "/unmute #general",
        category: "moderation"
      }
    ]

    categories = ["all" | commands |> Enum.map(& &1.category) |> Enum.uniq() |> Enum.sort()]

    socket =
      assign(socket,
        commands: commands,
        filtered_commands: commands,
        categories: categories,
        search_text: "",
        selected_category: "all"
      )

    {:ok, socket}
  end

  def update(assigns, socket) do
    socket = assign(socket, assigns)
    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <div>
      <.modal
        id="commands-modal"
        title="Chat Commands"
        show={@is_open}
        on_cancel={JS.patch(@return_to)}
      >
        <div class="border-b border-gray-700 p-4">
          <input
            type="text"
            placeholder="Search commands..."
            value={@search_text}
            phx-keyup="search"
            phx-target={@myself}
            class="search-input"
          />
        </div>

        <div class="flex flex-wrap gap-2 border-b border-gray-700 p-4">
          <%= for category <- @categories do %>
            <button
              phx-click="select_category"
              phx-value-category={category}
              phx-target={@myself}
              class={[
                "rounded-xs px-4 py-2",
                @selected_category == category && "bg-primary-700 text-cybertext-200",
                @selected_category != category &&
                  "bg-midnight-600 text-cybertext-400 duration-200 transition-colors cursor-pointer hover:bg-midnight-500"
              ]}
            >
              {String.capitalize(category)}
            </button>
          <% end %>
        </div>

        <div class="h-[50vh] overflow-y-auto p-4">
          <div class="grid grid-cols-1 gap-3 md:grid-cols-2">
            <%= for command <- @filtered_commands do %>
              <div class="bg-midnight-700 overflow-hidden rounded-xs border border-gray-700">
                <div class="bg-midnight-900 flex items-center justify-between border-b border-gray-700 px-3 py-2">
                  <div class="text-primary-400 font-mono">/{command.name}</div>

                  <div class="bg-midnight-900 text-cybertext-500 rounded-xs px-2 py-0.5 text-xs capitalize">
                    {command.category}
                  </div>
                </div>

                <div class="p-3">
                  <div class="mb-2">{command.description}</div>

                  <span class="text-cybertext-400 text-sm">Usage:</span>

                  <div class="border-l border-verdant-700 text-cybertext-500 bg-midnight-600 rounded-xs p-2 font-mono text-xs">
                    {command.example}
                  </div>
                </div>
              </div>
            <% end %>
          </div>

          <%= if Enum.empty?(@filtered_commands) do %>
            <div class="bg-midnight-700 rounded-xs border border-gray-700 p-6 text-center">
              <div class="mb-2">No commands found</div>

              <div class="text-cybertext-500 text-sm">
                Try a different search term or category
              </div>
            </div>
          <% end %>
        </div>

        <div class="text-cybertext-500 border-t border-gray-700 p-3 text-sm">
          Tip: You can use <span class="text-primary-400 font-mono">/help [command]</span>
          in chat to quickly see usage information
        </div>
      </.modal>
    </div>
    """
  end

  # Event handlers
  def handle_event("close", _, socket) do
    send(self(), {:close_commands})
    {:noreply, socket}
  end

  def handle_event("search", %{"value" => search_text}, socket) do
    filtered_commands =
      filter_commands(socket.assigns.commands, search_text, socket.assigns.selected_category)

    {:noreply, assign(socket, search_text: search_text, filtered_commands: filtered_commands)}
  end

  def handle_event("select_category", %{"category" => category}, socket) do
    filtered_commands =
      filter_commands(socket.assigns.commands, socket.assigns.search_text, category)

    {:noreply, assign(socket, selected_category: category, filtered_commands: filtered_commands)}
  end

  defp filter_commands(commands, search_text, category) do
    commands
    |> Enum.filter(fn cmd ->
      matches_search =
        search_text == "" ||
          String.contains?(String.downcase(cmd.name), String.downcase(search_text)) ||
          String.contains?(String.downcase(cmd.description), String.downcase(search_text))

      matches_category =
        category == "all" || cmd.category == category

      matches_search && matches_category
    end)
  end
end
