defmodule PearsWeb.TeamSettingsLive do
  use PearsWeb, :live_view
  use OpenTelemetryDecorator

  alias Pears.Accounts

  @decorate trace("team_settings_live.mount")
  def mount(%{"token" => token}, _session, socket) do
    socket =
      case Accounts.update_team_email(socket.assigns.current_team, token) do
        :ok ->
          O11y.set_attribute(:info, "Email changed successfully.")
          put_flash(socket, :info, "Email changed successfully.")

        :error ->
          O11y.set_error("Email change link is invalid or it has expired.")
          put_flash(socket, :error, "Email change link is invalid or it has expired.")
      end

    {:ok, push_navigate(socket, to: ~p"/teams/settings")}
  end

  @decorate trace("team_settings_live.mount")
  def mount(_params, _session, socket) do
    team = socket.assigns.current_team
    name_changeset = Accounts.change_team_name(team)

    socket =
      socket
      |> assign(:current_password, nil)
      |> assign(:name_form_current_password, nil)
      |> assign(:current_name, team.name)
      |> assign(:name_form, to_form(name_changeset))

    {:ok, socket}
  end

  def handle_event("validate_name", params, socket) do
    %{"current_password" => password, "team" => team_params} = params

    name_form =
      socket.assigns.current_team
      |> Accounts.change_team_name(team_params)
      |> Map.put(:action, :validate)
      |> to_form()

    {:noreply, assign(socket, name_form: name_form, name_form_current_password: password)}
  end

  @decorate trace("team_settings_live.update_name")
  def handle_event("update_name", params, socket) do
    %{"current_password" => password, "team" => team_params} = params
    team = socket.assigns.current_team
    O11y.set_attribute(:team_id, team.id)

    case Accounts.update_team_name(team, password, team_params) do
      {:ok, _} ->
        info = "Name changed successfully."
        {:noreply, socket |> put_flash(:info, info) |> assign(email_form_current_password: nil)}

      {:error, changeset} ->
        Pears.O11y.set_changeset_errors(changeset)
        {:noreply, assign(socket, name_form: to_form(changeset))}
    end
  end

  @decorate trace("team_settings_live.remove_team")
  def handle_event("remove_team", _params, socket) do
    team = socket.assigns.current_team
    O11y.set_attributes(:team, team)

    Pears.remove_team(team.name)

    {:noreply,
     socket
     |> put_flash(:info, "Team removed 😞✌️")
     |> redirect(to: ~p"/teams/register")}
  end
end
