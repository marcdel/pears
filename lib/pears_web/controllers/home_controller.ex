defmodule PearsWeb.HomeController do
  use PearsWeb, :controller

  def show(conn, _params) do
    case conn.assigns[:current_team] do
      %{name: team_name} -> redirect(conn, to: Routes.team_path(conn, :show, team_name))
      _ -> redirect(conn, to: Routes.team_registration_path(conn, :new))
    end
  end
end
