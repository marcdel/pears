defmodule PearsWeb.TeamConfirmationInstructionsLive do
  use PearsWeb, :live_view

  alias Pears.Accounts

  def render(assigns) do
    ~H"""
    <.header>Resend confirmation instructions</.header>

    <.simple_form for={@form} id="resend_confirmation_form" phx-submit="send_instructions">
      <.input field={@form[:email]} type="email" label="Email" required />
      <:actions>
        <.button phx-disable-with="Sending...">Resend confirmation instructions</.button>
      </:actions>
    </.simple_form>

    <p>
      <.link href={~p"/teams/register"}>Register</.link>
      |
      <.link href={~p"/teams/log_in"}>Log in</.link>
    </p>
    """
  end

  def mount(_params, _session, socket) do
    {:ok, assign(socket, form: to_form(%{}, as: "team"))}
  end

  def handle_event("send_instructions", %{"team" => %{"email" => email}}, socket) do
    if team = Accounts.get_team_by_email(email) do
      Accounts.deliver_team_confirmation_instructions(
        team,
        &url(~p"/teams/confirm/#{&1}")
      )
    end

    info =
      "If your email is in our system and it has not been confirmed yet, you will receive an email with instructions shortly."

    {:noreply,
     socket
     |> put_flash(:info, info)
     |> redirect(to: ~p"/")}
  end
end
