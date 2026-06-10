defmodule Pears.Core.Pear do
  # Keep slack_id/slack_name/timezone_offset off of span attributes
  @derive {O11y.SpanAttributes, only: [:id, :name, :order, :track]}
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

  @quittin_time ~T[17:00:00]

  def quittin_time?(pear, utc_now \\ DateTime.utc_now()) do
    # Shift utc_now by the pear's offset to get their local wall-clock time.
    # Anchoring 5pm local to Date.utc_today/0 instead would break for offsets
    # where 5pm local falls on a different UTC day (e.g. 5pm PST = 1am UTC).
    minutes_from_quittin =
      utc_now
      |> DateTime.add(pear.timezone_offset, :second)
      |> DateTime.to_time()
      |> Time.diff(@quittin_time, :minute)

    abs(minutes_from_quittin) < 30
  end
end
