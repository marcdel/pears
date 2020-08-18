defmodule Pears.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    OpenTelemetry.register_application_tracer(:pears)

    attach_timber_events()

    children = [
      # Start the Ecto repository
      Pears.Repo,
      # Start the Telemetry supervisor
      PearsWeb.Telemetry,
      # Start the PubSub system
      {Phoenix.PubSub, name: Pears.PubSub},
      # Start the Endpoint (http/https)
      PearsWeb.Endpoint,
      # Start a worker by calling: Pears.Worker.start_link(arg)
      # {Pears.Worker, arg}
      {Pears.Boundary.TeamManager, [name: Pears.Boundary.TeamManager]},
      {Registry, [name: Pears.Registry.TeamSession, keys: :unique]},
      {DynamicSupervisor, [name: Pears.Supervisor.TeamSession, strategy: :one_for_one]}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Pears.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    PearsWeb.Endpoint.config_change(changed, removed)
    :ok
  end

  defp attach_timber_events do
    :ok = :telemetry.attach(
      "timber-ecto-query-handler",
      [:pears, :repo, :query],
      &Timber.Ecto.handle_event/4,
      []
    )

    :ok = Logger.add_translator({Timber.Exceptions.Translator, :translate})
  end
end
