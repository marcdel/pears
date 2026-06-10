defmodule PearsWeb.TeamForgotPasswordLive do
  use PearsWeb, :live_view

  def render(assigns) do
    ~H"""
    <div class="mx-auto max-w-sm">
      <.header class="text-center">
        Password reset is currently unavailable
        <:subtitle>
          We can't send password reset emails right now. Please contact the
          site administrator if you've lost access to your account.
        </:subtitle>
      </.header>

      <p class="text-center mt-4">
        <.link href={~p"/teams/register"}>Register</.link>
        | <.link href={~p"/teams/log_in"}>Log in</.link>
      </p>
    </div>
    """
  end

  def mount(_params, _session, socket) do
    {:ok, socket}
  end
end
