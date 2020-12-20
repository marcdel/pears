defmodule Pears.Slack.Channel do
  defstruct [:id, :name]

  def from_json(json) do
    %__MODULE__{
      id: Map.get(json, "id"),
      name: Map.get(json, "name")
    }
  end
end
