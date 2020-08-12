defmodule PearsWeb.Telemetry do
  use Supervisor
  import Telemetry.Metrics

  alias Pears.Boundary.Instrumentation

  def start_link(arg) do
    Supervisor.start_link(__MODULE__, arg, name: __MODULE__)
  end

  @impl true
  def init(_arg) do
    children = [
      # Telemetry poller will execute the given period measurements
      # every 60_000ms, or 1 minute. Learn more here: https://hexdocs.pm/telemetry_metrics
      {:telemetry_poller, measurements: periodic_measurements(), period: 60_000}
      # Add reporters as children of your supervision tree.
      # {Telemetry.Metrics.ConsoleReporter, metrics: metrics()}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end

  def metrics do
    [
      # Phoenix Metrics
      summary("phoenix.endpoint.stop.duration",
        unit: {:native, :millisecond}
      ),
      summary("phoenix.router_dispatch.stop.duration",
        tags: [:route],
        unit: {:native, :millisecond}
      ),

      # Database Metrics
      summary("pears.repo.query.total_time", unit: {:native, :millisecond}),
      summary("pears.repo.query.decode_time", unit: {:native, :millisecond}),
      summary("pears.repo.query.query_time", unit: {:native, :millisecond}),
      summary("pears.repo.query.queue_time", unit: {:native, :millisecond}),
      summary("pears.repo.query.idle_time", unit: {:native, :millisecond}),

      # VM Metrics
      summary("vm.memory.total", unit: {:byte, :kilobyte}),
      summary("vm.total_run_queue_lengths.total"),
      summary("vm.total_run_queue_lengths.cpu"),
      summary("vm.total_run_queue_lengths.io"),

      # App Metrics
      summary("pears.teams.count")
    ]
  end

  defp periodic_measurements do
    [
      # A module, function and arguments to be invoked periodically.
      # This function must call :telemetry.execute/3 and a metric must be added above.
      {Instrumentation, :count_teams, []}
    ]
  end
end
