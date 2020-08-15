defmodule PearsWeb.Telemetry do
  use Supervisor
  import Telemetry.Metrics

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
      # {Telemetry.Metrics.ConsoleReporter, metrics: app_metrics()}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end

  def metrics do
    app_metrics() ++ phoenix_metrics() ++ database_metrics() ++ vm_metrics()
  end

  defp app_metrics do
    []
  end

  defp phoenix_metrics do
    [
      summary(
        "phoenix.endpoint.stop.duration",
        unit: {:native, :millisecond}
      ),
      summary(
        "phoenix.router_dispatch.stop.duration",
        tags: [:route],
        unit: {:native, :millisecond}
      )
    ]
  end

  defp database_metrics do
    [
      summary("pears.repo.query.total_time", unit: {:native, :millisecond}),
      summary("pears.repo.query.decode_time", unit: {:native, :millisecond}),
      summary("pears.repo.query.query_time", unit: {:native, :millisecond}),
      summary("pears.repo.query.queue_time", unit: {:native, :millisecond}),
      summary("pears.repo.query.idle_time", unit: {:native, :millisecond})
    ]
  end

  defp vm_metrics do
    [
      summary("vm.memory.total", unit: {:byte, :kilobyte}),
      summary("vm.total_run_queue_lengths.total"),
      summary("vm.total_run_queue_lengths.cpu"),
      summary("vm.total_run_queue_lengths.io")
    ]
  end

  defp periodic_measurements do
    [
      # A module, function and arguments to be invoked periodically.
      # This function must call :telemetry.execute/3 and a metric must be added above.
      # {Instrumentation, :count_teams, []}
    ]
  end
end
