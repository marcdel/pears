defmodule PearsWeb.TeamLoginLive do
  use PearsWeb, :live_view
  use OpenTelemetryDecorator

  def render(assigns) do
    ~H"""
    <div class="mx-auto max-w-sm">
      <.header class="text-center">
        Sign in to account
        <:subtitle>
          Don't have an account?
          <.link navigate={~p"/teams/register"} class="font-semibold text-brand hover:underline">
            Sign up
          </.link>
          for an account now.
        </:subtitle>
      </.header>

      <.simple_form for={@form} id="login_form" action={~p"/teams/log_in"} phx-update="ignore">
        <.input field={@form[:name]} type="text" label="Name" required />
        <.input field={@form[:password]} type="password" label="Password" required />

        <:actions>
          <.input field={@form[:remember_me]} type="checkbox" label="Keep me logged in" />
          <.link href={~p"/teams/reset_password"} class="text-sm font-semibold">
            Forgot your password?
          </.link>
        </:actions>
        <:actions>
          <.button phx-disable-with="Signing in..." class="w-full">
            Sign in <span aria-hidden="true">→</span>
          </.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @decorate trace("PearsWeb.TeamLoginLive.mount", include: [:name, :socket])
  def mount(_params, _session, socket) do
    name = live_flash(socket.assigns.flash, :name)
    form = to_form(%{"name" => name}, as: "team")
    {:ok, assign(socket, form: form), temporary_assigns: [form: form]}
  end
end
