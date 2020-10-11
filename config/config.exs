# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
use Mix.Config

config :pears,
  ecto_repos: [Pears.Repo]

# Configures the endpoint
config :pears, PearsWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "yaoPrOOBTKpirt8RtNjlCx1iK0beb0ojiT7hPcO7Idnj1+mW0EEQ/YW604UN+dYm",
  render_errors: [view: PearsWeb.ErrorView, accepts: ~w(html json), layout: false],
  pubsub_server: Pears.PubSub,
  live_view: [signing_salt: "hrGJfYm/"]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

config :pears, Pears.Repo, log: false

config :fun_with_flags, :cache_bust_notifications, enabled: false

config :fun_with_flags, :persistence,
  adapter: FunWithFlags.Store.Persistent.Ecto,
  repo: Pears.Repo,
  ecto_table_name: "feature_flags"

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
