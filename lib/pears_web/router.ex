defmodule PearsWeb.Router do
  use PearsWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, {PearsWeb.LayoutView, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  import Plug.BasicAuth

  pipeline :admins_only do
    if Mix.env() in [:dev, :prod, :e2e] do
      plug :basic_auth,
        username: Map.fetch!(System.get_env(), "ADMIN_USER"),
        password: Map.fetch!(System.get_env(), "ADMIN_PASSWORD")
    else
      plug :basic_auth, username: "admin", password: "admin"
    end
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", PearsWeb do
    pipe_through :browser

    live "/", PageLive, :index
    live "/teams/:id", TeamLive, :show
    live "/teams/:id/add_pear", TeamLive, :add_pear
    live "/teams/:id/add_track", TeamLive, :add_track
  end

  # Other scopes may use custom stacks.
  # scope "/api", PearsWeb do
  #   pipe_through :api
  # end

  if Mix.env() in [:e2e] do
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
    pipe_through [:browser, :admins_only]
    live_dashboard "/dashboard"
  end
end
