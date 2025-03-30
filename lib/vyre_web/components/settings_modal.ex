defmodule VyreWeb.Components.SettingsModal do
  use VyreWeb, :live_component

  def mount(socket) do
    blocked_users = [
      %{id: 501, username: "spammer123"},
      %{id: 502, username: "annoyinguser"}
    ]

    settings = %{
      appearance: %{
        theme: "midnight",
        font_size: "medium",
        message_density: "comfortable",
        animations_enabled: true,
        use_system_theme: false
      },
      notifications: %{
        sounds: true,
        desktop_notifications: true,
        mentions_only: false,
        mute_channels: []
      },
      privacy: %{
        show_status: true,
        allow_direct_messages: "friends",
        display_current_activity: true
      },
      accessibility: %{
        reduced_motion: false,
        high_contrast: false,
        screen_reader_optimized: false
      }
    }

    socket =
      assign(socket,
        active_tab: "appearance",
        has_changes: false,
        blocked_users: blocked_users,
        settings: settings,
        original_settings: settings
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
      <.modal id="settings-modal" title="Settings" show={@is_open} on_cancel={JS.patch(@return_to)}>
        <div class="flex flex-1 h-[70vh]">
          <!-- Settings Sidebar -->
          <div class="bg-midnight-900 w-48 border-r border-gray-700 h-full flex flex-col">
            <div class="flex flex-col h-full">
              <%= for {tab, label} <- [
                {"appearance", "Appearance"},
                {"notifications", "Notifications"},
                {"privacy", "Privacy"},
                {"blocked", "Blocked Users"},
                {"accessibility", "Accessibility"},
                {"about", "About"}
              ] do %>
                <button
                  phx-click="set_tab"
                  phx-value-tab={tab}
                  phx-target={@myself}
                  class={[
                    "hover:bg-midnight-500 mt-1 px-4 py-3 text-left transition-colors duration-200 ease-in-out",
                    @active_tab == tab && "bg-midnight-500 text-primary-400",
                    @active_tab != tab && "text-cybertext-400"
                  ]}
                >
                  {label}
                </button>
              <% end %>
            </div>
          </div>

          <div class="flex-1 p-6">
            <!-- Settings Content -->
            <%= case @active_tab do %>
              <% "appearance" -> %>
                <.appearance_tab settings={@settings.appearance} myself={@myself} />
              <% "notifications" -> %>
                <.notifications_tab settings={@settings.notifications} myself={@myself} />
              <% "privacy" -> %>
                <.privacy_tab settings={@settings.privacy} myself={@myself} />
              <% "blocked" -> %>
                <.blocked_tab blocked_users={@blocked_users} myself={@myself} />
              <% "accessibility" -> %>
                <.accessibility_tab settings={@settings.accessibility} myself={@myself} />
              <% "about" -> %>
                <.about_tab />
            <% end %>
          </div>

          <div class="self-end p-2">
            <%= if @has_changes do %>
              <div class="text-warning-400 mr-auto flex items-center text-sm">
                <svg
                  xmlns="http://www.w3.org/2000/svg"
                  class="mr-1 h-4 w-4"
                  viewBox="0 0 20 20"
                  fill="currentColor"
                >
                  <path
                    fill-rule="evenodd"
                    d="M8.257 3.099c.765-1.36 2.722-1.36 3.486 0l5.58 9.92c.75 1.334-.213 2.98-1.742 2.98H4.42c-1.53 0-2.493-1.646-1.743-2.98l5.58-9.92zM11 13a1 1 0 11-2 0 1 1 0 012 0zm-1-8a1 1 0 00-1 1v3a1 1 0 002 0V6a1 1 0 00-1-1z"
                    clip-rule="evenodd"
                  />
                </svg>
                Unsaved changes
              </div>
            <% end %>

            <.form for={%{}} action={~p"/users/logout"} method="delete" class="inline">
              <.button class="bg-error-600 hover:bg-error-500 text-cybertext-200 mr-3" type="submit">
                Log Out
              </.button>
            </.form>

            <.button
              phx-click={
                JS.push("close_modal", value: %{id: @id}) |> JS.exec("data-cancel", to: "##{@id}")
              }
              class="bg-midnight-400 hover:bg-midnight-300 text-cybertext-300 mr-3"
            >
              Cancel
            </.button>

            <.button
              phx-click="save_settings"
              phx-target={@myself}
              disabled={!@has_changes}
              class={
                if @has_changes,
                  do: "bg-primary-600 hover:bg-primary-500 text-cybertext-200",
                  else: "bg-primary-800 cursor-not-allowed text-gray-500"
              }
            >
              Save Changes
            </.button>
          </div>
        </div>
      </.modal>
    </div>
    """
  end

  # Individual tab components
  def appearance_tab(assigns) do
    ~H"""
    <div>
      <h3 class="text-cybertext-200 mb-4 font-mono text-lg">
        Appearance
      </h3>

      <div class="mb-6">
        <label class="text-cybertext-300 mb-2 block">
          Font Size
        </label>
        <div class="flex gap-3">
          <%= for size <- ["small", "medium", "large"] do %>
            <button
              phx-click="update_setting"
              phx-value-category="appearance"
              phx-value-setting="font_size"
              phx-value-value={size}
              phx-target={@myself}
              class={[
                "rounded-xs px-4 py-2",
                @settings.font_size == size && "bg-primary-700 text-cybertext-200",
                @settings.font_size != size &&
                  "bg-midnight-500 text-cybertext-400 hover:bg-midnight-600"
              ]}
            >
              {String.capitalize(size)}
            </button>
          <% end %>
        </div>
      </div>

      <div class="mb-6">
        <label class="text-cybertext-300 mb-2 block">
          Message Density
        </label>

        <div class="flex gap-3">
          <%= for density <- ["compact", "comfortable"] do %>
            <button
              phx-click="update_setting"
              phx-value-category="appearance"
              phx-value-setting="message_density"
              phx-value-value={density}
              phx-target={@myself}
              class={[
                "rounded-xs px-4 py-2",
                @settings.message_density == density && "bg-primary-700 text-cybertext-200",
                @settings.message_density != density &&
                  "bg-midnight-500 text-cybertext-400 hover:bg-midnight-600"
              ]}
            >
              {String.capitalize(density)}
            </button>
          <% end %>
        </div>
      </div>

      <div class="mb-4 flex items-center">
        <input
          type="checkbox"
          id="animations-toggle"
          checked={@settings.animations_enabled}
          phx-click="toggle_setting"
          phx-value-category="appearance"
          phx-value-setting="animations_enabled"
          phx-target={@myself}
          class="accent-verdant-500"
        />
        <label for="animations-toggle" class="ml-2">
          Enable animations
        </label>
      </div>
    </div>
    """
  end

  def notifications_tab(assigns) do
    ~H"""
    <div>
      <h3 class="text-cybertext-200 mb-4 font-mono text-lg">
        Notifications
      </h3>

      <div class="space-y-4">
        <div class="flex items-center justify-between">
          <label class="text-cybertext-300">Enable sounds</label>
          <input
            type="checkbox"
            checked={@settings.sounds}
            phx-click="toggle_setting"
            phx-value-category="notifications"
            phx-value-setting="sounds"
            phx-target={@myself}
            class="accent-verdant-500"
          />
        </div>

        <div class="flex items-center justify-between">
          <label class="text-cybertext-300">Desktop notifications</label>
          <input
            type="checkbox"
            checked={@settings.desktop_notifications}
            phx-click="toggle_setting"
            phx-value-category="notifications"
            phx-value-setting="desktop_notifications"
            phx-target={@myself}
            class="accent-verdant-500"
          />
        </div>

        <div class="flex items-center justify-between">
          <label class="text-cybertext-300">Only notify for mentions</label>
          <input
            type="checkbox"
            checked={@settings.mentions_only}
            phx-click="toggle_setting"
            phx-value-category="notifications"
            phx-value-setting="mentions_only"
            phx-target={@myself}
            class="accent-verdant-500"
          />
        </div>
      </div>

      <div class="mt-8">
        <h4 class="text-cybertext-300 mb-2 font-mono">Muted Channels</h4>
        <p class="text-cybertext-500 mb-4 text-sm">
          You won't receive notifications from these channels
        </p>

        <div class="bg-midnight-900 rounded-xs border border-gray-700 p-3">
          <%= if Enum.empty?(@settings.mute_channels) do %>
            <div class="text-sm text-gray-500">No muted channels</div>
          <% else %>
            <%= for channel <- @settings.mute_channels do %>
              <div class="flex items-center justify-between py-1">
                <span class="text-cybertext-400 channel-name">{channel}</span>
                <button
                  class="hover:text-error-400 text-gray-500"
                  phx-click="unmute_channel"
                  phx-value-channel={channel}
                  phx-target={@myself}
                >
                  ×
                </button>
              </div>
            <% end %>
          <% end %>
        </div>
      </div>
    </div>
    """
  end

  def privacy_tab(assigns) do
    ~H"""
    <div>
      <h3 class="text-cybertext-200 mb-4 font-mono text-lg">
        Privacy
      </h3>

      <div class="space-y-6">
        <div>
          <label class="text-cybertext-300 mb-2 block">
            Show online status
          </label>
          <div class="flex items-center">
            <input
              type="checkbox"
              id="status-toggle"
              checked={@settings.show_status}
              phx-click="toggle_setting"
              phx-value-category="privacy"
              phx-value-setting="show_status"
              phx-target={@myself}
              class="accent-verdant-500"
            />

            <label for="status-toggle" class="text-cybertext-500 ml-2 text-sm">
              Others can see when you're online
            </label>
          </div>
        </div>

        <div>
          <label class="text-cybertext-300 mb-2 block">
            Direct Messages
          </label>
          <select
            phx-change="update_select"
            phx-target={@myself}
            name="allow_direct_messages"
            class="bg-midnight-900 text-cybertext-300 w-full rounded-xs border border-gray-700 px-3 py-2"
          >
            <%= for {value, label} <- [
              {"everyone", "Allow from everyone"},
              {"friends", "Friends only"},
              {"server-members", "Server members only"},
              {"none", "Disabled"}
            ] do %>
              <option value={value} selected={@settings.allow_direct_messages == value}>
                {label}
              </option>
            <% end %>
          </select>
        </div>

        <div>
          <label class="text-cybertext-300 mb-2 block">
            Activity Status
          </label>
          <div class="flex items-center">
            <input
              type="checkbox"
              id="activity-toggle"
              checked={@settings.display_current_activity}
              phx-click="toggle_setting"
              phx-value-category="privacy"
              phx-value-setting="display_current_activity"
              phx-target={@myself}
              class="accent-verdant-500"
            />

            <label for="activity-toggle" class="text-cybertext-500 ml-2 text-sm">
              Display your current activity to others
            </label>
          </div>
        </div>
      </div>
    </div>
    """
  end

  def blocked_tab(assigns) do
    ~H"""
    <div>
      <h3 class="text-cybertext-200 mb-4 font-mono text-lg">
        Blocked Users
      </h3>

      <p class="text-cybertext-500 mb-4 text-sm">
        You won't receive messages or notifications from blocked users
      </p>

      <div class="bg-midnight-900 rounded-xs border border-gray-700">
        <%= if Enum.empty?(@blocked_users) do %>
          <div class="p-4 text-center text-gray-500">
            No blocked users
          </div>
        <% else %>
          <div class="stagger-children">
            <%= for user <- @blocked_users do %>
              <div class="flex items-center justify-between border-b border-gray-800 p-3 last:border-b-0">
                <div class="flex items-center">
                  <div class="mr-3 flex h-8 w-8 items-center justify-center rounded-xs bg-gray-800 text-xs">
                    {String.first(user.username)}
                  </div>
                  <span class="text-cybertext-400 user-name">
                    {user.username}
                  </span>
                </div>
                <button
                  phx-click="unblock_user"
                  phx-value-user-id={user.id}
                  phx-target={@myself}
                  class="bg-midnight-500 hover:bg-midnight-600 text-cybertext-300 rounded-xs px-3 py-1 text-sm"
                >
                  Unblock
                </button>
              </div>
            <% end %>
          </div>
        <% end %>
      </div>
    </div>
    """
  end

  def accessibility_tab(assigns) do
    ~H"""
    <div>
      <h3 class="text-cybertext-200 mb-4 font-mono text-lg">
        Accessibility
      </h3>

      <div class="space-y-4">
        <div class="flex items-center justify-between">
          <label class="text-cybertext-300">Reduced motion</label>

          <input
            type="checkbox"
            checked={@settings.reduced_motion}
            phx-click="toggle_setting"
            phx-value-category="accessibility"
            phx-value-setting="reduced_motion"
            phx-target={@myself}
            class="accent-verdant-500"
          />
        </div>

        <div class="flex items-center justify-between">
          <label class="text-cybertext-300">High contrast mode</label>

          <input
            type="checkbox"
            checked={@settings.high_contrast}
            phx-click="toggle_setting"
            phx-value-category="accessibility"
            phx-value-setting="high_contrast"
            phx-target={@myself}
            class="accent-verdant-500"
          />
        </div>

        <div class="flex items-center justify-between">
          <label class="text-cybertext-300">Screen reader optimized</label>

          <input
            type="checkbox"
            checked={@settings.screen_reader_optimized}
            phx-click="toggle_setting"
            phx-value-category="accessibility"
            phx-value-setting="screen_reader_optimized"
            phx-target={@myself}
            class="accent-verdant-500"
          />
        </div>
      </div>
    </div>
    """
  end

  def about_tab(assigns) do
    ~H"""
    <div>
      <h3 class="text-cybertext-200 mb-4 font-mono text-lg">
        About Vyre
      </h3>

      <div class="space-y-4">
        <div class="bg-midnight-900 scanlines rounded-xs border border-gray-700 p-4">
          <div class="text-cybertext-200 primary-glow mb-2 text-center font-mono text-xl">
            Vyre Chat
          </div>
          <div class="text-cybertext-500 mb-4 text-center">
            Version 0.9.1 Beta
          </div>

          <div class="mb-4 flex justify-center">
            <div class="bg-primary-900/50 text-primary-400 glitch-text rounded-xs px-3 py-1 text-sm">
              Development Build
            </div>
          </div>

          <p class="text-cybertext-400 mb-2 text-sm">
            A modern chat platform with IRC roots. Lightweight,
            customizable, and privacy-focused.
          </p>

          <p class="text-cybertext-500 text-sm">
            Created with Phoenix LiveView and a passion for cyberpunk aesthetics.
          </p>
        </div>

        <div class="flex justify-center space-x-4">
          <.link
            href="https://github.com/aileks/Vyre"
            target="_blank"
            rel="noopener noreferrer"
            class="bg-midnight-500 hover:bg-midnight-600 text-cybertext-300 rounded-xs px-4 py-2 text-sm transition-colors duration-200 ease-in-out"
          >
            GitHub
          </.link>

          <.link
            href="#"
            class="bg-midnight-500 hover:bg-midnight-600 text-cybertext-300 rounded-xs px-4 py-2 text-sm transition-colors duration-200 ease-in-out"
          >
            Website
          </.link>

          <.link
            href="#"
            class="bg-midnight-500 hover:bg-midnight-600 text-cybertext-300 rounded-xs px-4 py-2 text-sm transition-colors duration-200 ease-in-out"
          >
            Report Bug
          </.link>
        </div>
      </div>
    </div>
    """
  end

  # Event handlers
  def handle_event("set_tab", %{"tab" => tab}, socket) do
    {:noreply, assign(socket, active_tab: tab)}
  end

  def handle_event(
        "update_setting",
        %{"category" => category, "setting" => setting, "value" => value},
        socket
      ) do
    socket =
      update_in(
        socket.assigns.settings[String.to_atom(category)][String.to_atom(setting)],
        fn _ -> value end
      )

    {:noreply, check_changes(socket)}
  end

  def handle_event("toggle_setting", %{"category" => category, "setting" => setting}, socket) do
    socket =
      update_in(
        socket.assigns.settings[String.to_atom(category)][String.to_atom(setting)],
        fn current -> !current end
      )

    {:noreply, check_changes(socket)}
  end

  # Fixed event handler for select change
  def handle_event("update_select", %{"allow_direct_messages" => value}, socket) do
    socket = update_in(socket.assigns.settings.privacy.allow_direct_messages, fn _ -> value end)
    {:noreply, check_changes(socket)}
  end

  def handle_event("unmute_channel", %{"channel" => channel}, socket) do
    socket =
      update_in(socket.assigns.settings.notifications.mute_channels, fn channels ->
        Enum.reject(channels, &(&1 == channel))
      end)

    {:noreply, check_changes(socket)}
  end

  def handle_event("unblock_user", %{"user-id" => user_id}, socket) do
    user_id = String.to_integer(user_id)

    socket =
      assign(socket,
        blocked_users: Enum.reject(socket.assigns.blocked_users, &(&1.id == user_id))
      )

    {:noreply, assign(socket, has_changes: true)}
  end

  def handle_event("save_settings", _, socket) do
    socket =
      assign(socket,
        original_settings: socket.assigns.settings,
        has_changes: false
      )

    {:noreply, push_patch(socket, to: socket.assigns.return_to || "/")}
  end

  defp check_changes(socket) do
    has_changes = socket.assigns.settings != socket.assigns.original_settings
    assign(socket, has_changes: has_changes)
  end
end
