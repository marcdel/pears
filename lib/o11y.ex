defmodule O11y do
  require OpenTelemetry.Tracer, as: Tracer
  alias OpenTelemetryDecorator.Attributes

  def set_attribute(key, value), do: Attributes.set(key, value)

  def set_attributes(attributes), do: Attributes.set(attributes)

  def set_team(nil), do: nil

  def set_team(%Pears.Accounts.Team{} = team) do
    O11y.set_attributes(%{team_id: team.id, team_name: team.name})
    team
  end

  def set_team(%Phoenix.LiveView.Socket{} = socket) do
    set_team(socket.assigns.team)
    socket
  end

  def record_exception(exception) do
    Tracer.record_exception(exception)
    Tracer.set_status(OpenTelemetry.status(:error))
  end

  def set_error do
    Tracer.set_status(OpenTelemetry.status(:error))
  end

  def set_error(error) do
    set_attribute("error", error)
    Tracer.set_status(OpenTelemetry.status(:error))
  end

  def set_changeset_errors(%Ecto.Changeset{} = changeset) do
    error_string =
      changeset
      |> Ecto.Changeset.traverse_errors(fn {msg, _} -> msg end)
      |> Enum.map(fn {field, errors} -> "#{field}: #{Enum.join(errors, ", ")}" end)
      |> Enum.join(", ")

    set_error(error_string)
  end
end
