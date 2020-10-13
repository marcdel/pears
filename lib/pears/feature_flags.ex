defmodule FeatureFlagsBehavior do
  @type options :: Keyword.t()

  @callback disable(atom, options) :: {:ok, false}
  @callback enable(atom, options) :: {:ok, true}
  @callback enabled?(atom, options) :: boolean
end

defimpl FunWithFlags.Actor, for: Pears.Core.Team do
  def id(%{name: name}), do: "team:#{name}"
end

defmodule Pears.FeatureFlags do
  @behaviour FeatureFlagsBehavior

  def disable(atom, options \\ []), do: FunWithFlags.disable(atom, options)
  def enable(atom, options \\ []), do: FunWithFlags.enable(atom, options)
  def enabled?(atom, options \\ []), do: FunWithFlags.enabled?(atom, options)
end
