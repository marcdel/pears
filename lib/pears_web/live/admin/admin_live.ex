defmodule PearsWeb.AdminLive do
  use PearsWeb, :live_view
  use OpenTelemetryDecorator

  alias Pears.Persistence.RecordCounts

  @impl true
  @decorate trace("admin_live.mount", include: [:total_teams, :total_records, :percent_full])
  def mount(params, session, socket) do
    total_records = RecordCounts.total()
    percent_full = RecordCounts.percent_full()
    total_teams = RecordCounts.team_count()

    {:ok,
     assign(socket,
       total_teams: total_teams,
       total_records: total_records,
       percent_full: percent_full
     )}
  end
end
