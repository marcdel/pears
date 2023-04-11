defmodule PearsWeb.TeamForgotPasswordLive do
  use PearsWeb, :live_view

  alias Pears.Accounts

  def render(assigns) do
    ~H"""
    <div class="mx-auto max-w-sm">
      <.header class="text-center">
        Forgot your password?
        <:subtitle>We'll send a password reset link to your inbox</:subtitle>
      </.header>

      <.simple_form for={@form} id="reset_password_form" phx-submit="send_email">
        <.input field={@form[:email]} type="email" placeholder="Email" required />
        <:actions>
          <.button phx-disable-with="Sending..." class="w-full">
            Send password reset instructions
          </.button>
        </:actions>
      </.simple_form>
      <p class="text-center mt-4">
        <.link href={~p"/teams/register"}>Register</.link>
        | <.link href={~p"/teams/log_in"}>Log in</.link>
      </p>
    </div>
    """
  end

  def mount(_params, _session, socket) do
    {:ok, assign(socket, form: to_form(%{}, as: "team"))}
  end

  def handle_event("send_email", %{"team" => %{"email" => email}}, socket) do
    if team = Accounts.get_team_by_email(email) do
      Accounts.deliver_team_reset_password_instructions(
        team,
        &url(~p"/teams/reset_password/#{&1}")
      )
    end

    info =
      "If your email is in our system, you will receive instructions to reset your password shortly."

    {:noreply,
     socket
     |> put_flash(:info, info)
     |> redirect(to: ~p"/")}
  end
end
