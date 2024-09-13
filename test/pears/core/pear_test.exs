defmodule Pears.Core.PearTest do
  use ExUnit.Case, async: true

  alias Pears.Core.Pear

  describe "new/1" do
    test "creates a new pear with the given fields" do
      pear =
        Pear.new(%{
          id: 1,
          name: "Pear",
          track: "Track",
          order: 1,
          slack_id: "slack_id",
          slack_name: "slack_name",
          timezone_offset: -18000
        })

      assert pear.id == 1
      assert pear.name == "Pear"
      assert pear.track == "Track"
      assert pear.order == 1
      assert pear.slack_id == "slack_id"
      assert pear.slack_name == "slack_name"
      assert pear.timezone_offset == -18000
    end
  end

  describe "quittin_time?" do
    test "returns true if the current UTC time is near 5pm in Greece" do
      do_test_timezone(2)
    end

    test "returns true if the current UTC time is near 5pm Eastern" do
      do_test_timezone(-5)
    end

    test "returns true if the current UTC time is near 5pm Pacific" do
      do_test_timezone(-8)
    end

    def do_test_timezone(timezone_offset_hours) do
      offset_seconds = Pears.TzHelpers.hours_to_seconds(timezone_offset_hours)
      pear = Pear.new(%{timezone_offset: offset_seconds})

      local_5pm = Pears.TzHelpers.five_pm_in_local_time(offset_seconds)
      local_4pm = DateTime.add(local_5pm, -1, :hour)
      local_6pm = DateTime.add(local_5pm, 1, :hour)

      local_4pm_in_utc = Pears.TzHelpers.local_time_to_utc(local_4pm)
      local_5pm_in_utc = Pears.TzHelpers.local_time_to_utc(local_5pm)
      local_6pm_in_utc = Pears.TzHelpers.local_time_to_utc(local_6pm)

      assert Pear.quittin_time?(pear, local_4pm_in_utc) == false

      assert Pear.quittin_time?(pear, DateTime.add(local_5pm_in_utc, -29, :minute)) == true
      assert Pear.quittin_time?(pear, local_5pm_in_utc) == true
      assert Pear.quittin_time?(pear, DateTime.add(local_5pm_in_utc, 29, :minute)) == true

      assert Pear.quittin_time?(pear, local_6pm_in_utc) == false
    end
  end
end
