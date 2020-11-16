defmodule PearsWeb.Router do
  use PearsWeb, :router

  import PearsWeb.TeamAuth

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, {PearsWeb.LayoutView, :logged_out}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :fetch_current_team
  end

  pipeline :logged_in do
    plug :put_root_layout, {PearsWeb.LayoutView, :logged_in}
  end

  pipeline :logged_out do
    plug :put_root_layout, {PearsWeb.LayoutView, :logged_out}
  end

  import Plug.BasicAuth

  pipeline :admins_only do
    if Mix.env() == :test do
      plug :basic_auth, username: "admin", password: "admin"
    else
      plug :basic_auth,
        username: Map.fetch!(System.get_env(), "ADMIN_USER"),
        password: Map.fetch!(System.get_env(), "ADMIN_PASSWORD")
    end
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  # Other scopes may use custom stacks.
  # scope "/api", PearsWeb do
  #   pipe_through :api
  # end

  if Mix.env() in [:e2e, :ci] do
    forward("/e2e", PearsWeb.Plug.TestEndToEnd)
  end

  # Enables LiveDashboard only for development
  #
  # If you want to use the LiveDashboard in production, you should put
  # it behind authentication and allow only admins to access it.
  # If your application does not have an admins-only section yet,
  # you can use Plug.BasicAuth to set up some basic authentication
  # as long as you are also using SSL (which you should anyway).
  import Phoenix.LiveDashboard.Router

  scope "/" do
    pipe_through [:browser, :logged_in, :admins_only]

    live_dashboard "/dashboard", metrics: PearsWeb.Telemetry
    forward "/feature-flags", FunWithFlags.UI.Router, namespace: "feature-flags"
    live "/admin", PearsWeb.AdminLive, :show
  end

  ## Authentication routes

  scope "/", PearsWeb do
    pipe_through [:browser, :logged_out, :redirect_if_team_is_authenticated]

    get "/teams/register", TeamRegistrationController, :new
    post "/teams/register", TeamRegistrationController, :create
    get "/teams/log_in", TeamSessionController, :new
    post "/teams/log_in", TeamSessionController, :create
  end

  scope "/", PearsWeb do
    pipe_through [:browser, :logged_in, :require_authenticated_team]

    get "/teams/settings", TeamSettingsController, :edit
    put "/teams/settings/update_password", TeamSettingsController, :update_password
    put "/teams/settings/update_name", TeamSettingsController, :update_name

    live "/teams/:id", TeamLive, :show
    live "/teams/:id/add_pear", TeamLive, :add_pear
    live "/teams/:id/add_track", TeamLive, :add_track
  end

  scope "/", PearsWeb do
    pipe_through [:browser, :logged_out]

    get "/", HomeController, :show
    # live "/", PageLive, :index
    delete "/teams/log_out", TeamSessionController, :delete
  end
end
