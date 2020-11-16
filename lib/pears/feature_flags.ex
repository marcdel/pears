defmodule FeatureFlagsBehavior do
  @type options :: Keyword.t()

  @callback disable(atom(), list()) :: {:ok, false}
  @callback enable(atom(), list()) :: {:ok, true}
  @callback enabled?(atom(), list()) :: boolean
end

defimpl FunWithFlags.Actor, for: Pears.Core.Team do
  def id(%{name: name}), do: "team:#{name}"
end

defmodule FeatureFlags do
  @behaviour FeatureFlagsBehavior

  use OpenTelemetryDecorator

  @decorate trace("flags.disable", include: [:flag_name, :options, :result])
  def disable(flag_name, options \\ []) do
    FunWithFlags.disable(flag_name, options)
  end

  @decorate trace("flags.enable", include: [:flag_name, :options, :result])
  def enable(flag_name, options \\ []) do
    FunWithFlags.enable(flag_name, options)
  end

  def enabled?(flag_name, options \\ [])

  @decorate trace("flags.enabled?", include: [:flag_name, [:team, :name], :result])
  def enabled?(flag_name, for: team) do
    FunWithFlags.enabled?(flag_name, for: team)
  end

  @decorate trace("flags.enabled?", include: [:flag_name, :options, :result])
  def enabled?(flag_name, options) do
    FunWithFlags.enabled?(flag_name, options)
  end
end
