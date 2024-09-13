defmodule Pears.TzHelpersTest do
  use ExUnit.Case, async: true

  alias Pears.TzHelpers

  describe "five_pm_in_local_time/1" do
    test "returns 12pm UTC for EST" do
      utc_minus_5 = TzHelpers.hours_to_seconds(-5)
      local_5pm = TzHelpers.five_pm_in_local_time(utc_minus_5)
      assert DateTime.to_time(local_5pm) == ~T[12:00:00]
    end

    test "returns 9ap UTC for PST" do
      utc_minus_8 = TzHelpers.hours_to_seconds(-8)
      local_5pm = TzHelpers.five_pm_in_local_time(utc_minus_8)
      assert DateTime.to_time(local_5pm) == ~T[09:00:00]
    end
  end

  describe "five_pm_in_utc_time/0" do
    test "returns 5pm UTC" do
      utc_5pm = TzHelpers.five_pm_in_utc_time()
      assert DateTime.to_time(utc_5pm) == ~T[17:00:00]
    end
  end
end
