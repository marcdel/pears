defmodule Pears.Slack.User do
  defstruct [:id, :name, :tz_offset]

  def from_json(json) do
    %__MODULE__{
      id: Map.get(json, "id"),
      name: Map.get(json, "name"),
      tz_offset: Map.get(json, "tz_offset")
    }
  end
end
