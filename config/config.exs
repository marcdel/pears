# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

config :pears,
  ecto_repos: [Pears.Repo]

# Configures the endpoint
config :pears, PearsWeb.Endpoint,
  url: [host: "localhost"],
  render_errors: [
    formats: [html: PearsWeb.ErrorHTML, json: PearsWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: Pears.PubSub,
  live_view: [signing_salt: "8iJZvs0b"]

# Configures the mailer
#
# By default it uses the "Local" adapter which stores the emails
# locally. You can see the emails in your browser, at "/dev/mailbox".
#
# For production it's recommended to configure a different adapter
# at the `config/runtime.exs`.
config :pears, Pears.Mailer, adapter: Swoosh.Adapters.Local

# Configure esbuild (the version is required)
config :esbuild,
  version: "0.14.41",
  default: [
    args:
      ~w(js/app.js --bundle --target=es2017 --outdir=../priv/static/assets --external:/fonts/* --external:/images/*),
    cd: Path.expand("../assets", __DIR__),
    env: %{"NODE_PATH" => Path.expand("../deps", __DIR__)}
  ]

# Configure tailwind (the version is required)
config :tailwind,
  version: "3.2.4",
  default: [
    args: ~w(
      --config=tailwind.config.js
      --input=css/app.css
      --output=../priv/static/assets/app.css
    ),
    cd: Path.expand("../assets", __DIR__)
  ]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

config :fun_with_flags, :cache_bust_notifications, enabled: false

config :fun_with_flags, :persistence,
  adapter: FunWithFlags.Store.Persistent.Ecto,
  repo: Pears.Repo,
  ecto_table_name: "feature_flags"

config :pears, slack_client_id: Map.fetch!(System.get_env(), "SLACK_CLIENT_ID")
config :pears, slack_client_secret: Map.fetch!(System.get_env(), "SLACK_CLIENT_SECRET")
config :pears, slack_oauth_redirect_uri: Map.get(System.get_env(), "SLACK_OAUTH_URL")

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
