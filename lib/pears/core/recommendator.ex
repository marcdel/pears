defmodule Pears.Core.Recommendator do
  alias Pears.Core.Team

  def assign_pears(team) do
    team = Enum.reduce(team.available_pears, team, &assign_preferred_matches/2)
    Enum.reduce(team.available_pears, team, &assign_remaining_matches/2)
  end

  defp assign_preferred_matches({pear_name, pear}, team) do
    case Team.find_available_pear(team, pear_name) do
      nil -> team
      _pear -> do_assign_preferred_matches({pear_name, pear}, team)
    end
  end

  defp do_assign_preferred_matches({pear_name, _pear}, team) do
    case preferred_match(team, pear_name) do
      {nil, nil} ->
        team

      {match_name, nil} ->
        track = find_empty_track(team)

        team
        |> Team.add_pear_to_track(pear_name, track.name)
        |> Team.add_pear_to_track(match_name, track.name)

      {_match_name, track} ->
        Team.add_pear_to_track(team, pear_name, track.name)
    end
  end

  defp assign_remaining_matches({pear_name, _pear}, team) do
    case find_available_track(team) do
      nil -> team
      track -> Team.add_pear_to_track(team, pear_name, track.name)
    end
  end

  defp find_available_track(team) do
    with nil <- find_incomplete_track(team),
         nil <- find_empty_track(team) do
      nil
    else
      track -> track
    end
  end

  defp find_incomplete_track(team) do
    case Enum.find(team.tracks, fn {_name, track} -> Enum.count(track.pears) == 1 end) do
      {_, track} -> track
      _ -> nil
    end
  end

  defp find_empty_track(team) do
    case Enum.find(team.tracks, fn {_name, track} -> Enum.empty?(track.pears) end) do
      {_, track} -> track
      _ -> nil
    end
  end

  defp potential_matches(team, pear_name) do
    assigned_pears =
      team
      |> Team.assigned_pears()
      |> Enum.find([], fn pears -> Enum.count(pears) == 1 end)
      |> Enum.filter(fn p -> p != pear_name end)

    available_pears =
      team.available_pears
      |> Enum.map(fn {name, _} -> name end)
      |> Enum.filter(fn p -> p != pear_name end)

    (available_pears ++ assigned_pears)
    |> Enum.map(fn match -> [pear_name, match] end)
  end

  defp preferred_matches(team, pear_name) do
    team
    |> potential_matches(pear_name)
    |> Enum.reject(fn match -> Team.match_in_history?(team, match) end)
  end

  defp preferred_match(team, pear_name) do
    case team
         |> preferred_matches(pear_name)
         |> List.first() do
      [_, match_name] ->
        case Team.where_is_pear?(team, match_name) do
          {:assigned, track} -> {match_name, track}
          _ -> {match_name, nil}
        end

      _ ->
        {nil, nil}
    end
  end
end
