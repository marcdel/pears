defmodule Pears.TzHelpers do
  def five_pm_in_local_time(offset_seconds) do
    utc_to_local_time(~T[17:00:00], offset_seconds)
  end

  def five_pm_in_utc_time do
    DateTime.new!(Date.utc_today(), ~T[17:00:00], "Etc/UTC")
  end

  def utc_to_local_time(time, offset) do
    Date.utc_today()
    |> DateTime.new!(time, "Etc/UTC")
    |> DateTime.add(offset, :second)
  end

  def local_time_to_utc(local_time) do
    DateTime.shift_zone!(local_time, "Etc/UTC")
  end

  def date_time_to_time(date_time) do
    DateTime.to_time(date_time)
  end

  def hours_to_seconds(hours) do
    hours * 60 * 60
  end

  def seconds_to_hours(seconds) do
    seconds / 60 / 60
  end
end
