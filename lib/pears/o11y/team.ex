defmodule Pears.O11y.Team do
  alias Pears.O11y.Tracer

  def add_pear(team, pear_name, callback) do
    event_name = [:pears, :team, :add_pear]
    metadata = %{pear_name: pear_name}

    Tracer.trace_team_event(
      event_name: event_name,
      metadata: metadata,
      team: team,
      callback: callback
    )
  end

  def add_track(team, track_name, callback) do
    event_name = [:pears, :team, :add_track]
    metadata = %{track_name: track_name}

    Tracer.trace_team_event(
      event_name: event_name,
      metadata: metadata,
      team: team,
      callback: callback
    )
  end

  def add_pear_to_track(team, pear_name, track_name, callback) do
    event_name = [:pears, :team, :add_pear_to_track]
    metadata = %{pear_name: pear_name, track_name: track_name}

    Tracer.trace_team_event(
      event_name: event_name,
      metadata: metadata,
      team: team,
      callback: callback
    )
  end

  def move_pear_to_track(team, pear_name, from_track_name, to_track_name, callback) do
    event_name = [:pears, :team, :move_pear_to_track]

    metadata = %{
      pear_name: pear_name,
      from_track_name: from_track_name,
      to_track_name: to_track_name
    }

    Tracer.trace_team_event(
      event_name: event_name,
      metadata: metadata,
      team: team,
      callback: callback
    )
  end

  def remove_pear_from_track(team, pear_name, track_name, callback) do
    event_name = [:pears, :team, :remove_pear_from_track]
    metadata = %{pear_name: pear_name, track_name: track_name}

    Tracer.trace_team_event(
      event_name: event_name,
      metadata: metadata,
      team: team,
      callback: callback
    )
  end

  def record_pears(team, callback) do
    event_name = [:pears, :team, :record_pears]

    Tracer.trace_team_event(
      event_name: event_name,
      team: team,
      callback: callback
    )
  end
end
