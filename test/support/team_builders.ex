defmodule TeamBuilders do
  alias Pears.Core.Team

  def team do
    Team.new(name: "Team #{random_id()}")
  end

  defp random_id do
    Enum.random(1..1_000)
  end
end
