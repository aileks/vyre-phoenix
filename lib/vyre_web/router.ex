defmodule VyreWeb.Router do
  use VyreWeb, :router

  import VyreWeb.UserAuth

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {VyreWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :fetch_current_user
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", VyreWeb do
    pipe_through :browser

    live "/", HomeLive, :index
  end

  ## Authentication routes

  scope "/", VyreWeb do
    pipe_through [:browser, :redirect_if_user_is_authenticated]

    live_session :redirect_if_user_is_authenticated,
      on_mount: [{VyreWeb.UserAuth, :redirect_if_user_is_authenticated}] do
      live "/users/register", UserRegistrationLive, :new
      live "/users/login", UserLoginLive, :new
      live "/users/reset", UserForgotPasswordLive, :new
      live "/users/reset/:token", UserResetPasswordLive, :edit
    end

    post "/users/login", UserSessionController, :create
  end

  scope "/", VyreWeb do
    pipe_through [:browser, :require_authenticated_user]

    live_session :require_authenticated_user,
      on_mount: [{VyreWeb.UserAuth, :ensure_authenticated}] do
      live "/users/settings", UserSettingsLive, :edit
      live "/users/settings/confirm/:token", UserSettingsLive, :confirm_email
    end
  end

  scope "/", VyreWeb do
    pipe_through [:browser]

    delete "/users/logout", UserSessionController, :delete

    live_session :current_user,
      on_mount: [{VyreWeb.UserAuth, :mount_current_user}] do
      live "/users/confirm/:token", UserConfirmationLive, :edit
      live "/users/confirm", UserConfirmationInstructionsLive, :new
    end
  end

  scope "/app", VyreWeb do
    pipe_through [:browser, :require_authenticated_user]

    live_session :app,
      on_mount: [{VyreWeb.UserAuth, :ensure_authenticated}, VyreWeb.SidebarHook],
      layout: {VyreWeb.Layouts, :app} do
      live "/", AppLive, :index
      live "/friends", AppLive, :friends
      live "/channels/:id", ChannelLive.Show, :show
    end
  end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:vyre, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: VyreWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end
end
