defmodule DeepGame.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      DeepGameWeb.Telemetry,
      {DNSCluster, query: Application.get_env(:deep_game, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: DeepGame.PubSub},
      # Start a worker by calling: DeepGame.Worker.start_link(arg)
      # {DeepGame.Worker, arg},
      # Start to serve requests, typically the last entry
      DeepGameWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: DeepGame.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    DeepGameWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
