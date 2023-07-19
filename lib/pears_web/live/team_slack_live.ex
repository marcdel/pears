defmodule PearsWeb.TeamSlackLive do
  use PearsWeb, :live_view

  def render(%{live_action: :edit} = assigns) do
    ~H"""
    <div class="lg:grid lg:grid-cols-12 lg:gap-x-5">
      <.live_component module={PearsWeb.SettingsNav} id="settings_nav" current_path={@current_path} />
      <div class="space-y-6 sm:px-6 lg:col-span-9 lg:px-0">
        <h1>Slack</h1>
      </div>
    </div>
    """
  end

  def mount(_params, _session, socket) do
    {:ok, socket}
  end
end
