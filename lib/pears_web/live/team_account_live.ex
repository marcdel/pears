defmodule PearsWeb.TeamAccountLive do
  use PearsWeb, :live_view
  use OpenTelemetryDecorator

  alias Pears.Accounts

  @decorate trace("team_account_live.mount")
  def mount(%{"token" => token}, _session, socket) do
    socket =
      case Accounts.update_team_email(socket.assigns.current_team, token) do
        :ok ->
          O11y.set_attribute(:info, "Email changed successfully.")
          put_flash(socket, :info, "Email changed successfully.")

        :error ->
          O11y.set_attribute(:error, "Email change link is invalid or it has expired.")
          put_flash(socket, :error, "Email change link is invalid or it has expired.")
      end

    {:ok, push_navigate(socket, to: ~p"/teams/settings")}
  end

  def mount(_params, _session, socket) do
    team = socket.assigns.current_team
    email_changeset = Accounts.change_team_email(team)
    password_changeset = Accounts.change_team_password(team)

    socket =
      socket
      |> assign(:current_password, nil)
      |> assign(:email_form_current_password, nil)
      |> assign(:current_name, team.name)
      |> assign(:current_email, team.email)
      |> assign(:email_form, to_form(email_changeset))
      |> assign(:password_form, to_form(password_changeset))
      |> assign(:trigger_submit, false)

    {:ok, socket}
  end

  def handle_event("validate_email", params, socket) do
    %{"current_password" => password, "team" => team_params} = params

    email_form =
      socket.assigns.current_team
      |> Accounts.change_team_email(team_params)
      |> Map.put(:action, :validate)
      |> to_form()

    {:noreply, assign(socket, email_form: email_form, email_form_current_password: password)}
  end

  def handle_event("update_email", params, socket) do
    %{"current_password" => password, "team" => team_params} = params
    team = socket.assigns.current_team

    case Accounts.apply_team_email(team, password, team_params) do
      {:ok, applied_team} ->
        Accounts.deliver_team_update_email_instructions(
          applied_team,
          team.email,
          &url(~p"/teams/settings/confirm_email/#{&1}")
        )

        info = "A link to confirm your email change has been sent to the new address."
        {:noreply, socket |> put_flash(:info, info) |> assign(email_form_current_password: nil)}

      {:error, changeset} ->
        {:noreply, assign(socket, :email_form, to_form(Map.put(changeset, :action, :insert)))}
    end
  end

  def handle_event("validate_password", params, socket) do
    %{"current_password" => password, "team" => team_params} = params

    password_form =
      socket.assigns.current_team
      |> Accounts.change_team_password(team_params)
      |> Map.put(:action, :validate)
      |> to_form()

    {:noreply, assign(socket, password_form: password_form, current_password: password)}
  end

  def handle_event("update_password", params, socket) do
    %{"current_password" => password, "team" => team_params} = params
    team = socket.assigns.current_team

    case Accounts.update_team_password(team, password, team_params) do
      {:ok, team} ->
        password_form =
          team
          |> Accounts.change_team_password(team_params)
          |> to_form()

        {:noreply, assign(socket, trigger_submit: true, password_form: password_form)}

      {:error, changeset} ->
        {:noreply, assign(socket, password_form: to_form(changeset))}
    end
  end
end
