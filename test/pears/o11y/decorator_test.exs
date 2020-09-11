defmodule Pears.O11y.DecoratorTest do
  use ExUnit.Case, async: true

  alias Pears.O11y.Decorator

  describe "validate_args" do
    test "event name must be a non-empty list of atoms" do
      Decorator.validate_args([:name, :space, :event], [])

      assert_raise ArgumentError, ~r/^event_name/, fn ->
        Decorator.validate_args("name.space.event", [])
      end
    end

    test "attr_keys can be empty" do
      Decorator.validate_args([:name, :space, :event], [])
    end

    test "attrs_keys must be atoms" do
      Decorator.validate_args([:name, :space, :event], [:variable])

      assert_raise ArgumentError, ~r/^attr_keys/, fn ->
        Decorator.validate_args([:name, :space, :event], ["variable"])
      end
    end

    test "attrs_keys can contain nested lists of atoms" do
      Decorator.validate_args([:name, :space, :event], [:variable, [:obj, :key]])
    end
  end

  describe "take_attrs" do
    test "handles flat attributes" do
      assert Decorator.take_attrs([id: 1], [:id]) == [id: 1]
    end

    test "handles nested attributes" do
      assert Decorator.take_attrs([team: %{id: 1}], [[:team, :id]]) == [team_id: 1]
    end

    test "handles flat and nested attributes" do
      attrs = Decorator.take_attrs([error: "whoops", team: %{id: 1}], [:error, [:team, :id]])
      assert attrs == [team_id: 1, error: "whoops"]
    end

    test "can take the top level element and a nested attribute" do
      attrs = Decorator.take_attrs([team: %{id: 1}], [:team, [:team, :id]])
      assert attrs == [team_id: 1, team: %{id: 1}]
    end

    test "handles multiply nested attributes" do
      attrs = Decorator.take_attrs([team: %{pear: %{id: 2}}], [[:team, :pear, :id]])
      assert attrs == [team_pear_id: 2]

      attrs =
        Decorator.take_attrs(
          [team: %{pear: %{track: %{id: 3}}}],
          [[:team, :pear, :track, :id]]
        )

      assert attrs == [team_pear_track_id: 3]
    end

    test "does not add attribute if missing" do
      attrs = Decorator.take_attrs([team: %{}], [[:team, :id]])
      assert attrs == []

      attrs = Decorator.take_attrs([], [[:team, :id]])
      assert attrs == []
    end
  end

  describe "maybe_add_result" do
    test "when :result is given, adds result to the list" do
      attrs = Decorator.maybe_add_result([], [:result], {:ok, "include me"})
      assert attrs == [result: {:ok, "include me"}]

      attrs = Decorator.maybe_add_result([id: 10], [:result, :id], {:ok, "include me"})
      assert attrs == [result: {:ok, "include me"}, id: 10]
    end

    test "when :result is missing, does not add result to the list" do
      attrs = Decorator.maybe_add_result([], [], {:ok, "include me"})
      assert attrs == []

      attrs = Decorator.maybe_add_result([name: "blah"], [:name], {:ok, "include me"})
      assert attrs == [name: "blah"]
    end
  end

  describe "remove_underscores" do
    test "removes underscores from keys" do
      assert Decorator.remove_underscores(_id: 1) == [id: 1]
      assert Decorator.remove_underscores(_id: 1, _name: "asd") == [id: 1, name: "asd"]
    end

    test "doesn't modify keys without underscores" do
      assert Decorator.remove_underscores(_id: 1, name: "asd") == [id: 1, name: "asd"]
    end
  end

  describe "stringify_list" do
    test "doesn't modify strings" do
      attrs = Decorator.stringify_list(string_attr: "hello")
      assert attrs == [string_attr: "hello"]
    end

    test "doesn't modify integers" do
      attrs = Decorator.stringify_list(int_attr: 12)
      assert attrs == [int_attr: 12]
    end

    test "stringifies maps" do
      attrs = Decorator.stringify_list(team: %{id: 10})
      assert attrs == [team: "%{id: 10}"]
    end

    test "stringifies structs" do
      attrs =
        Decorator.stringify_list(
          team: %Pears.Core.Team{
            assigned_pears: %{},
            available_pears: %{},
            history: [],
            id: nil,
            name: nil,
            tracks: %{}
          }
        )

      assert attrs == [
               team:
                 "%Pears.Core.Team{assigned_pears: %{}, available_pears: %{}, history: [], id: nil, name: nil, tracks: %{}}"
             ]
    end

    test "stringifies lists" do
      attrs = Decorator.stringify_list(matches: [1, 2, 3, 4])
      assert attrs == [matches: "[1, 2, 3, 4]"]

      attrs = Decorator.stringify_list(matches: [{"pear 1", "pear 2"}, {"pear 3", "pear 4"}])
      assert attrs == [matches: "[{\"pear 1\", \"pear 2\"}, {\"pear 3\", \"pear 4\"}]"]
    end
  end
end
