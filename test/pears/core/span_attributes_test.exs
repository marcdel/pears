defmodule Pears.Core.SpanAttributesTest do
  # async: false — O11y.TestHelper stops/starts the :opentelemetry app per test
  use ExUnit.Case, async: false
  use O11y.TestHelper

  alias Pears.Core.AvailablePears
  alias Pears.Core.Pear
  alias Pears.Core.Team
  alias Pears.Core.Track

  # runtime.exs sets traces_exporter: :none in test, which overrides the pid
  # exporter otel_pid_reporter configures — point it at the test pid and restart.
  setup do
    Application.put_env(:opentelemetry, :traces_exporter, {:otel_exporter_pid, self()})
    Application.stop(:opentelemetry)
    {:ok, _} = Application.ensure_all_started(:opentelemetry)
    :ok
  end

  describe "struct attribute derivation" do
    test "pears only expose stable scalar fields" do
      pear =
        Pear.new(
          id: 1,
          name: "Pear One",
          order: 2,
          track: "Track One",
          slack_id: "UXXXXXXX",
          slack_name: "pear-one",
          timezone_offset: -28_800
        )

      keys = pear |> O11y.SpanAttributes.get() |> Enum.map(fn {key, _} -> to_string(key) end)

      assert Enum.sort(keys) == ["id", "name", "order", "track"]
    end

    test "tracks do not expose their name-keyed pears map" do
      track =
        Track.new(id: 1, name: "Track One", pears: %{})
        |> Track.add_pear(Pear.new(name: "Pear One"))

      keys = track |> O11y.SpanAttributes.get() |> Enum.map(fn {key, _} -> to_string(key) end)

      assert Enum.sort(keys) == ["anchor", "id", "locked", "name"]
    end
  end

  describe "traced functions" do
    test "adding an available pear does not emit attributes keyed by pear names" do
      available_pears = %{"Pear One" => Pear.new(name: "Pear One", order: 1)}

      AvailablePears.add_pear(available_pears, Pear.new(name: "Pear Two"))

      refute_span_attribute_keys_contain("available_pears.add_pear", ["Pear One", "Pear Two"])
    end

    test "assigning a pear does not emit attributes keyed by pear or track names" do
      team =
        Team.new(name: "Team One")
        |> Team.add_pear("Pear One")
        |> Team.add_track("Track One")

      Team.add_pear_to_track(team, "Pear One", "Track One")

      refute_span_attribute_keys_contain("team.add_pear_to_track", ["Pear One", "Track One"])
    end

    test "choosing anchors does not emit attributes keyed by track names" do
      team =
        Team.new(name: "Team One")
        |> Team.add_pear("Pear One")
        |> Team.add_track("Track One")
        |> Team.add_pear_to_track("Pear One", "Track One")

      Team.choose_anchors(team)

      refute_span_attribute_keys_contain("team.choose_anchors", ["Pear One", "Track One"])
    end
  end

  # Matches the raw span record via O11y.RecordDefinitions, which compiles
  # against the installed otel headers — unlike O11y.Span.from_record/1, which
  # hard-codes a record arity and breaks across opentelemetry versions.
  defp refute_span_attribute_keys_contain(span_name, names) do
    assert_receive {:span, span(name: ^span_name, attributes: attributes)}

    keys =
      attributes
      |> Tuple.to_list()
      |> List.last()
      |> Map.keys()
      |> Enum.map(&to_string/1)

    for key <- keys, name <- names do
      refute String.contains?(key, name),
             "expected no span attribute keyed by #{inspect(name)}, found #{inspect(key)}"
    end
  end
end
