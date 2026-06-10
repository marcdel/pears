defmodule Pears.Persistence.SnapshotRecordTest do
  use ExUnit.Case, async: true

  alias Pears.Persistence.SnapshotRecord

  describe "from_today?" do
    test "is true when the snapshot was inserted today" do
      snapshot = %SnapshotRecord{inserted_at: ~N[2026-06-10 12:00:00]}

      assert SnapshotRecord.from_today?(snapshot, ~D[2026-06-10])
    end

    test "is false when the snapshot was inserted on a previous day" do
      snapshot = %SnapshotRecord{inserted_at: ~N[2026-06-09 23:59:59]}

      refute SnapshotRecord.from_today?(snapshot, ~D[2026-06-10])
    end

    test "defaults to comparing against today's UTC date" do
      today_snapshot = %SnapshotRecord{inserted_at: NaiveDateTime.utc_now()}

      yesterday_snapshot = %SnapshotRecord{
        inserted_at: NaiveDateTime.add(NaiveDateTime.utc_now(), -1, :day)
      }

      assert SnapshotRecord.from_today?(today_snapshot)
      refute SnapshotRecord.from_today?(yesterday_snapshot)
    end
  end
end
