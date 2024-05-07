defmodule FeatureFlagsBehavior do
  @type options :: Keyword.t()

  @callback toggle(atom(), boolean()) :: {:ok, boolean()}
  @callback disable(atom(), list()) :: {:ok, false}
  @callback enable(atom(), list()) :: {:ok, true}
  @callback enabled?(atom(), list()) :: boolean
end

defimpl FunWithFlags.Actor, for: Pears.Core.Team do
  def id(%{name: name}), do: "team:#{name}"
end

defimpl FunWithFlags.Actor, for: Pears.Accounts.Team do
  def id(%{name: name}), do: "team:#{name}"
end

defmodule FeatureFlags do
  @behaviour FeatureFlagsBehavior

  use OpenTelemetryDecorator

  def toggle(flag_name, enable, options \\ [])

  def toggle(flag_name, true, options) do
    enable(flag_name, options)
  end

  def toggle(flag_name, false, options) do
    disable(flag_name, options)
  end

  @decorate trace("flags.disable", include: [:flag_name, :options, :result])
  def disable(flag_name, options \\ []) do
    FunWithFlags.disable(flag_name, options)
  end

  @decorate trace("flags.enable", include: [:flag_name, :options, :result])
  def enable(flag_name, options \\ []) do
    FunWithFlags.enable(flag_name, options)
  end

  def enabled?(flag_name, options \\ [])

  @decorate trace("flags.enabled?", include: [:flag_name, :team, :enabled])
  def enabled?(flag_name, for: team) do
    enabled = FunWithFlags.enabled?(flag_name, for: team)
    enabled
  end

  @decorate trace("flags.enabled?", include: [:flag_name, :options, :enabled])
  def enabled?(flag_name, options) do
    enabled = FunWithFlags.enabled?(flag_name, options)
    enabled
  end
end
