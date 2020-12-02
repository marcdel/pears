defmodule Pears.Slack.Channel do
  defstruct [:name]

  def from_json(json) do
    %__MODULE__{
      name: Map.get(json, "name")
    }
  end
end
