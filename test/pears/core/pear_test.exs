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
    @offsets [
      {"UTC", 0},
      {"UTC+2", 2},
      {"UTC-5 (EST)", -5},
      {"UTC-8 (PST, 5pm local is past midnight UTC)", -8},
      {"UTC+11 (5pm local is on the previous UTC day)", 11}
    ]

    for {label, offset_hours} <- @offsets do
      test "returns true within 30 minutes of 5pm local time (#{label})" do
        offset_seconds = unquote(offset_hours) * 60 * 60
        pear = Pear.new(%{timezone_offset: offset_seconds})

        # A fixed date (not Date.utc_today/0) so implementations anchored to
        # "today" in UTC fail when 5pm local falls on a different UTC day.
        utc_at_local_5pm =
          ~D[2026-01-15]
          |> DateTime.new!(~T[17:00:00], "Etc/UTC")
          |> DateTime.add(-offset_seconds, :second)

        assert Pear.quittin_time?(pear, DateTime.add(utc_at_local_5pm, -1, :hour)) == false

        assert Pear.quittin_time?(pear, DateTime.add(utc_at_local_5pm, -29, :minute)) == true
        assert Pear.quittin_time?(pear, utc_at_local_5pm) == true
        assert Pear.quittin_time?(pear, DateTime.add(utc_at_local_5pm, 29, :minute)) == true

        assert Pear.quittin_time?(pear, DateTime.add(utc_at_local_5pm, 1, :hour)) == false
      end
    end
  end
end
