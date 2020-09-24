use Mix.Config

config :pears, env: Mix.env()

config :pears, PearsWeb.Endpoint,
  http: [port: 5000],
  server: true

config :logger, level: :warn

config :pears, Pears.Repo,
  adapter: Ecto.Adapters.Postgres,
  username: "postgres",
  password: "postgres",
  database: "pears_ci",
  hostname: "localhost",
  pool: Ecto.Adapters.SQL.Sandbox

config :opentelemetry, :resource,
  service: [
    name: "pears",
    namespace: "pears_ci"
  ]

config :opentelemetry,
  processors: [
    ot_batch_processor: %{
      exporter:
        {OpenTelemetry.Honeycomb.Exporter,
         write_key: Map.fetch!(System.get_env(), "HONEYCOMB_KEY"), dataset: "pears"}
    }
  ]
