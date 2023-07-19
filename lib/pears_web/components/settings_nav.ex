defmodule PearsWeb.SettingsNav do
  use PearsWeb, :live_component
  use OpenTelemetryDecorator

  @impl true
  @decorate trace("settings_nav.mount")
  def mount(socket) do
    {:ok, socket}
  end
end
