defmodule Vyre.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    unless System.get_env("MIX_ENV") == "prod" do
      Dotenv.load()
      Mix.Task.run("loadconfig")
    end

    children = [
      VyreWeb.Telemetry,
      Vyre.Repo,
      {DNSCluster, query: Application.get_env(:vyre, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: Vyre.PubSub},
      # Start the Finch HTTP client for sending emails
      {Finch, name: Vyre.Finch},
      # Start a worker by calling: Vyre.Worker.start_link(arg)
      # {Vyre.Worker, arg},
      # Start to serve requests, typically the last entry
      VyreWeb.Endpoint,
      {Vyre.Channels.StatusCache, []},
      {Vyre.Channels.StatusQueue, []}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Vyre.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    VyreWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
