use Mix.Config

# Only in tests, remove the complexity from the password hashing algorithm
config :bcrypt_elixir, :log_rounds, 1

# Configure your database
#
# The MIX_TEST_PARTITION environment variable can be used
# to provide built-in test partitioning in CI environment.
# Run `mix help test` for more information.
config :pears, Pears.Repo,
  username: "postgres",
  password: "postgres",
  database: "pears_test#{System.get_env("MIX_TEST_PARTITION")}",
  hostname: "localhost",
  pool: Ecto.Adapters.SQL.Sandbox

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :pears, PearsWeb.Endpoint,
  http: [port: 4002],
  server: false

# Print only warnings and errors during test
config :logger, level: :warn

config :opentelemetry,
  processors: [
    ot_batch_processor: %{
      exporter:
        {OpenTelemetry.Honeycomb.Exporter,
         write_key: Map.fetch!(System.get_env(), "HONEYCOMB_KEY"), dataset: "pears_test"}
    }
  ]
