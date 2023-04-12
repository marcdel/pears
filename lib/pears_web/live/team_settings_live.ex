defmodule PearsWeb.TeamSettingsLive do
  use PearsWeb, :live_view

  alias Pears.Accounts

  def render(assigns) do
    ~H"""
    <.header>Change Name</.header>

    <.simple_form for={@name_form} id="name_form" phx-submit="update_name" phx-change="validate_name">
      <.input field={@name_form[:name]} type="text" label="Name" required />
      <.input
        field={@name_form[:current_password]}
        name="current_password"
        id="current_password_for_name"
        type="password"
        label="Current password"
        value={@name_form_current_password}
        required
      />
      <:actions>
        <.button phx-disable-with="Changing...">Change Name</.button>
      </:actions>
    </.simple_form>

    <.header>Change Email</.header>

    <.simple_form
      for={@email_form}
      id="email_form"
      phx-submit="update_email"
      phx-change="validate_email"
    >
      <.input field={@email_form[:email]} type="email" label="Email" required />
      <.input
        field={@email_form[:current_password]}
        name="current_password"
        id="current_password_for_email"
        type="password"
        label="Current password"
        value={@email_form_current_password}
        required
      />
      <:actions>
        <.button phx-disable-with="Changing...">Change Email</.button>
      </:actions>
    </.simple_form>

    <.header>Change Password</.header>

    <.simple_form
      for={@password_form}
      id="password_form"
      action={~p"/teams/log_in?_action=password_updated"}
      method="post"
      phx-change="validate_password"
      phx-submit="update_password"
      phx-trigger-action={@trigger_submit}
    >
      <.input field={@password_form[:name]} type="hidden" value={@current_name} />
      <.input field={@password_form[:password]} type="password" label="New password" required />
      <.input
        field={@password_form[:password_confirmation]}
        type="password"
        label="Confirm new password"
      />
      <.input
        field={@password_form[:current_password]}
        name="current_password"
        type="password"
        label="Current password"
        id="current_password_for_password"
        value={@current_password}
        required
      />
      <:actions>
        <.button phx-disable-with="Changing...">Change Password</.button>
      </:actions>
    </.simple_form>
    """
  end

  def mount(%{"token" => token}, _session, socket) do
    socket =
      case Accounts.update_team_email(socket.assigns.current_team, token) do
        :ok ->
          put_flash(socket, :info, "Email changed successfully.")

        :error ->
          put_flash(socket, :error, "Email change link is invalid or it has expired.")
      end

    {:ok, push_navigate(socket, to: ~p"/teams/settings")}
  end

  def mount(_params, _session, socket) do
    team = socket.assigns.current_team
    email_changeset = Accounts.change_team_email(team)
    name_changeset = Accounts.change_team_name(team)
    password_changeset = Accounts.change_team_password(team)

    socket =
      socket
      |> assign(:current_password, nil)
      |> assign(:email_form_current_password, nil)
      |> assign(:current_email, team.email)
      |> assign(:email_form, to_form(email_changeset))
      |> assign(:name_form_current_password, nil)
      |> assign(:current_name, team.name)
      |> assign(:name_form, to_form(name_changeset))
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

  def handle_event("validate_name", params, socket) do
    %{"current_password" => password, "team" => team_params} = params

    name_form =
      socket.assigns.current_team
      |> Accounts.change_team_name(team_params)
      |> Map.put(:action, :validate)
      |> to_form()

    {:noreply, assign(socket, name_form: name_form, name_form_current_password: password)}
  end

  def handle_event("update_name", params, socket) do
    %{"current_password" => password, "team" => team_params} = params
    team = socket.assigns.current_team

    case Accounts.update_team_name(team, password, team_params) do
      {:ok, _} ->
        info = "Name changed successfully."
        {:noreply, socket |> put_flash(:info, info) |> assign(email_form_current_password: nil)}

      {:error, changeset} ->
        {:noreply, assign(socket, name_form: to_form(changeset))}
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
