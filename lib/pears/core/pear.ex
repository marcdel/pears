defmodule Pears.Core.Pear do
  alias Pears.TzHelpers

  defstruct id: nil,
            name: nil,
            track: nil,
            order: nil,
            slack_id: nil,
            slack_name: nil,
            timezone_offset: nil

  def new(fields) do
    struct!(__MODULE__, fields)
  end

  def update(pear, params) do
    struct!(pear, params)
  end

  def set_order(pear, order) do
    %{pear | order: order}
  end

  def add_track(pear, track) do
    Map.put(pear, :track, track.name)
  end

  def remove_track(pear) do
    Map.put(pear, :track, nil)
  end

  def quittin_time?(pear, utc_now \\ DateTime.utc_now()) do
    minutes_from_5 =
      pear.timezone_offset
      |> TzHelpers.five_pm_in_local_time()
      |> TzHelpers.local_time_to_utc()
      |> DateTime.diff(utc_now, :minute)

    abs(minutes_from_5) < 30
  end
end
