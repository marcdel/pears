defmodule Pears.Core.RecommendatorPropertiesTest do
  use ExUnit.Case, async: true
  use ExUnitProperties

  alias Pears.Core.Recommendator
  alias Pears.Core.Team

  property "suggesting seats every pear and respects locks and user anchors" do
    check all team <- team_generator() do
      suggested = Recommendator.choose_anchors_and_suggest(team)

      assert Enum.empty?(suggested.available_pears),
             "every pear should be seated, but #{inspect(Map.keys(suggested.available_pears))} stayed on the bench"

      for track <- Map.values(suggested.tracks), not track.locked do
        assert map_size(track.pears) <= 2,
               "unlocked track #{track.name} ended up with #{map_size(track.pears)} pears"
      end

      for {name, track} <- team.tracks, track.locked do
        assert Map.keys(suggested.tracks[name].pears) == Map.keys(track.pears),
               "locked track #{name} was modified"
      end

      for {name, track} <- team.tracks do
        if track.anchor do
          assert suggested.tracks[name].anchor == track.anchor,
                 "user anchor on #{name} was not preserved"

          assert Map.has_key?(suggested.tracks[name].pears, track.anchor),
                 "anchor #{track.anchor} was moved off #{name}"
        else
          assert suggested.tracks[name].anchor == nil,
                 "auto-chosen anchor on #{name} was not cleared"
        end
      end
    end
  end

  defp team_generator do
    gen all pear_count <- integer(1..8),
            track_count <- integer(0..4),
            placements <- list_of(integer(0..track_count), length: pear_count),
            locked_flags <- list_of(boolean(), length: track_count),
            anchored_flags <- list_of(boolean(), length: track_count),
            history_rotations <- list_of(integer(0..7), max_length: 3) do
      pear_names = Enum.map(1..pear_count, &"pear#{&1}")
      track_names = if track_count == 0, do: [], else: Enum.map(1..track_count, &"track#{&1}")

      TeamBuilders.team()
      |> add_tracks(track_names)
      |> add_pears(pear_names)
      |> place_pears(pear_names, placements)
      |> put_history(pear_names, history_rotations)
      |> anchor_and_lock(track_names, anchored_flags, locked_flags)
    end
  end

  defp add_tracks(team, track_names) do
    Enum.reduce(track_names, team, &Team.add_track(&2, &1))
  end

  defp add_pears(team, pear_names) do
    Enum.reduce(pear_names, team, &Team.add_pear(&2, &1))
  end

  # Placement 0 leaves the pear on the bench; tracks may end up with any
  # number of pears, including more than two.
  defp place_pears(team, pear_names, placements) do
    pear_names
    |> Enum.zip(placements)
    |> Enum.reduce(team, fn
      {_pear, 0}, team -> team
      {pear, i}, team -> Team.add_pear_to_track(team, pear, "track#{i}")
    end)
  end

  # Each history day pairs up a rotation of the pear list, mimicking the
  # {track, [pears]} shape that record_pears writes.
  defp put_history(team, pear_names, rotations) do
    history =
      Enum.map(rotations, fn rotation ->
        pear_names
        |> rotate(rotation)
        |> Enum.chunk_every(2)
        |> Enum.with_index(1)
        |> Enum.map(fn {pair, i} -> {"track#{i}", pair} end)
      end)

    %{team | history: history}
  end

  defp anchor_and_lock(team, track_names, anchored_flags, locked_flags) do
    track_names
    |> Enum.zip(Enum.zip(anchored_flags, locked_flags))
    |> Enum.reduce(team, fn {track_name, {anchored, locked}}, team ->
      team
      |> maybe_anchor(track_name, anchored)
      |> maybe_lock(track_name, locked)
    end)
  end

  defp maybe_anchor(team, track_name, true) do
    case Map.keys(team.tracks[track_name].pears) do
      [] -> team
      [pear_name | _] -> Team.toggle_anchor(team, pear_name, track_name)
    end
  end

  defp maybe_anchor(team, _track_name, false), do: team

  defp maybe_lock(team, track_name, true), do: Team.lock_track(team, track_name)
  defp maybe_lock(team, _track_name, false), do: team

  defp rotate(list, 0), do: list

  defp rotate(list, n) do
    shift = rem(n, length(list))
    Enum.drop(list, shift) ++ Enum.take(list, shift)
  end
end
