defmodule ImportHistoryTest do
  use Pears.DataCase, async: true

  setup [:name]

  test "can import history from parrit", %{name: name} do
    Pears.add_team(name)
    Pears.add_pear(name, "Mansi")
    Pears.add_pear(name, "Kristin")
    Pears.add_pear(name, "Del")
    Pears.add_pear(name, "Nick")
    Pears.add_pear(name, "Iris")
    Pears.add_pear(name, "Palak")
    Pears.add_pear(name, "Luke")
    Pears.add_pear(name, "Randy")
    Pears.add_pear(name, "Marc")
    Pears.add_track(name, "Operator UI")
    Pears.add_track(name, "PTC API")
    Pears.add_track(name, "Pricing V4 ")
    Pears.add_track(name, "OOO/OC")

    json =
      ~s([{"pairingBoardName": "Operator UI", "people": [{"id": 17443, "name": "Mansi"}, {"id": 17641, "name": "Kristin"}], "pairingTime": "2020-08-03T16:53:53.098+0000"}, {"pairingBoardName": "PTC API", "people": [{"id": 16983, "name": "Del"}, {"id": 17859, "name": "Nick"}], "pairingTime": "2020-08-03T16:53:53.098+0000"}, {"pairingBoardName": "Pricing V4 ", "people": [{"id": 16981, "name": "Iris"}], "pairingTime": "2020-08-03T16:53:53.098+0000"}, {"pairingBoardName": "OOO/OC", "people": [{"id": 16982, "name": "Palak"}, {"id": 16985, "name": "Luke"}, {"id": 16980, "name": "Randy"}, {"id": 16984, "name": "Marc"}], "pairingTime": "2020-08-03T16:53:53.098+0000"}, {"pairingBoardName": "OOO/OC", "people": [{"id": 16985, "name": "Luke"}, {"id": 16980, "name": "Randy"}, {"id": 16984, "name": "Marc"}], "pairingTime": "2020-07-31T16:23:26.362+0000"}, {"pairingBoardName": "PTC API", "people": [{"id": 16981, "name": "Iris"}, {"id": 17859, "name": "Nick"}], "pairingTime": "2020-07-31T16:23:26.362+0000"}, {"pairingBoardName": "Pricing V4 ", "people": [{"id": 16983, "name": "Del"}, {"id": 16982, "name": "Palak"}], "pairingTime": "2020-07-31T16:23:26.362+0000"}, {"pairingBoardName": "Operator UI", "people": [{"id": 17443, "name": "Mansi"}, {"id": 17641, "name": "Kristin"}], "pairingTime": "2020-07-31T16:23:26.362+0000"}, {"pairingBoardName": "OOO/OC", "people": [{"id": 16985, "name": "Luke"}, {"id": 16980, "name": "Randy"}, {"id": 16984, "name": "Marc"}], "pairingTime": "2020-07-30T16:25:10.668+0000"}, {"pairingBoardName": "PTC API", "people": [{"id": 16982, "name": "Palak"}, {"id": 16981, "name": "Iris"}], "pairingTime": "2020-07-30T16:25:10.668+0000"}, {"pairingBoardName": "Pricing V4 ", "people": [{"id": 16983, "name": "Del"}, {"id": 17859, "name": "Nick"}], "pairingTime": "2020-07-30T16:25:10.668+0000"}, {"pairingBoardName": "Operator UI", "people": [{"id": 17443, "name": "Mansi"}, {"id": 17641, "name": "Kristin"}], "pairingTime": "2020-07-30T16:25:10.668+0000"}])

    team = ImportHistory.import_history_from_parrit_json(name, json)

    refute Enum.empty?(team.history)
    refute Enum.empty?(team.assigned_pears)
    assert Enum.empty?(team.available_pears)
  end

  def name(_) do
    {:ok, name: Ecto.UUID.generate()}
  end
end
