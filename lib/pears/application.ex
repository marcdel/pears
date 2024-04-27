defmodule Pears.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    OpentelemetryPhoenix.setup()
    OpentelemetryEcto.setup([:pears, :repo])

    children = [
      # Start the Telemetry supervisor
      PearsWeb.Telemetry,
      # Start the Ecto repository
      Pears.Repo,
      {DNSCluster, query: Application.get_env(:pears, :dns_cluster_query) || :ignore},
      Pears.Vault,
      # Start the PubSub system
      {Phoenix.PubSub, name: Pears.PubSub},
      # Start Finch
      {Finch, name: Pears.Finch},
      # Start the Endpoint (http/https)
      PearsWeb.Endpoint,
      # Start a worker by calling: Pears.Worker.start_link(arg)
      # {Pears.Worker, arg}
      {Pears.Boundary.TeamManager, [name: Pears.Boundary.TeamManager]},
      {Registry, [name: Pears.Registry.TeamSession, keys: :unique]},
      {DynamicSupervisor, [name: Pears.Supervisor.TeamSession, strategy: :one_for_one]},
      {Pears.Boundary.PruneSnapshots, []}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Pears.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    PearsWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
