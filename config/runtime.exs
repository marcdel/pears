import Config

# config/runtime.exs is executed for all environments, including
# during releases. It is executed after compilation and before the
# system starts, so it is typically used to load production configuration
# and secrets from environment variables or elsewhere. Do not define
# any compile-time configuration in here, as it won't be applied.
# The block below contains prod specific runtime configuration.
if config_env() == :prod do
  database_url =
    System.get_env("DATABASE_URL") ||
      raise """
      environment variable DATABASE_URL is missing.
      For example: ecto://USER:PASS@HOST/DATABASE
      """

  maybe_ipv6 = if System.get_env("ECTO_IPV6") in ~w(true 1), do: [:inet6], else: []

  config :pears, Pears.Repo,
    # ssl: true,
    url: database_url,
    pool_size: String.to_integer(System.get_env("POOL_SIZE") || "10"),
    socket_options: maybe_ipv6

  # The secret key base is used to sign/encrypt cookies and other secrets.
  # A default value is used in config/dev.exs and config/test.exs but you
  # want to use a different value for prod and you most likely don't want
  # to check this value into version control, so we use an environment
  # variable instead.
  secret_key_base =
    System.get_env("SECRET_KEY_BASE") ||
      raise """
      environment variable SECRET_KEY_BASE is missing.
      You can generate one by calling: mix phx.gen.secret
      """

  host = System.get_env("PHX_HOST") || "example.com"
  port = String.to_integer(System.get_env("PORT") || "4000")

  config :pears, :dns_cluster_query, System.get_env("DNS_CLUSTER_QUERY")

  config :pears, PearsWeb.Endpoint,
    url: [host: host, port: 443, scheme: "https"],
    http: [
      # Enable IPv6 and bind on all interfaces.
      # Set it to  {0, 0, 0, 0, 0, 0, 0, 1} for local network only access.
      # See the documentation on https://hexdocs.pm/bandit/Bandit.html#t:options/0
      # for details about using IPv6 vs IPv4 and loopback vs public addresses.
      ip: {0, 0, 0, 0, 0, 0, 0, 0},
      port: port
    ],
    check_origin: [
      "https://app.pears.dev",
      "https://pears-app.fly.dev",
      "https://welcome-duck-remarkably.ngrok-free.app"
    ],
    secret_key_base: secret_key_base

  config :pears, admin_user: System.fetch_env!("ADMIN_USER")
  config :pears, admin_password: System.fetch_env!("ADMIN_PASSWORD")

  config :sentry,
    dsn: System.fetch_env!("SENTRY_DSN_URL"),
    environment_name: config_env(),
    enable_source_code_context: true,
    root_source_code_paths: [File.cwd!()]

  # ## SSL Support
  #
  # To get SSL working, you will need to add the `https` key
  # to your endpoint configuration:
  #
  #     config :pears, PearsWeb.Endpoint,
  #       https: [
  #         ...,
  #         port: 443,
  #         cipher_suite: :strong,
  #         keyfile: System.get_env("SOME_APP_SSL_KEY_PATH"),
  #         certfile: System.get_env("SOME_APP_SSL_CERT_PATH")
  #       ]
  #
  # The `cipher_suite` is set to `:strong` to support only the
  # latest and more secure SSL ciphers. This means old browsers
  # and clients may not be supported. You can set it to
  # `:compatible` for wider support.
  #
  # `:keyfile` and `:certfile` expect an absolute path to the key
  # and cert in disk or a relative path inside priv, for example
  # "priv/ssl/server.key". For all supported SSL configuration
  # options, see https://hexdocs.pm/plug/Plug.SSL.html#configure/1
  #
  # We also recommend setting `force_ssl` in your config/prod.exs,
  # ensuring no data is ever sent via http, always redirecting to https:
  #
  #     config :pears, PearsWeb.Endpoint,
  #       force_ssl: [hsts: true]
  #
  # Check `Plug.SSL` for all available options in `force_ssl`.

  # ## Configuring the mailer
  #
  # In production you need to configure the mailer to use a different adapter.
  # Also, you may need to configure the Swoosh API client of your choice if you
  # are not using SMTP. Here is an example of the configuration:
  #
  #     config :pears, Pears.Mailer,
  #       adapter: Swoosh.Adapters.Mailgun,
  #       api_key: System.get_env("MAILGUN_API_KEY"),
  #       domain: System.get_env("MAILGUN_DOMAIN")
  #
  # For this example you need include a HTTP client required by Swoosh API client.
  # Swoosh supports Hackney and Finch out of the box:
  #
  #     config :swoosh, :api_client, Swoosh.ApiClient.Hackney
  #
  # See https://hexdocs.pm/swoosh/Swoosh.html#module-installation for details.
else
  config :pears, admin_user: "admin", admin_password: "admin"
end

# ## Using releases
#
# If you use `mix release`, you need to explicitly enable the server
# by passing the PHX_SERVER=true when you start it:
#
#     PHX_SERVER=true bin/pears start
#
# Alternatively, you can use `mix phx.gen.release` to generate a `bin/server`
# script that automatically sets the env var above.
if System.get_env("PHX_SERVER") do
  config :pears, PearsWeb.Endpoint, server: true
end

config :pears, slack_client_id: System.fetch_env!("SLACK_CLIENT_ID")
config :pears, slack_client_secret: System.fetch_env!("SLACK_CLIENT_SECRET")
config :pears, slack_oauth_redirect_uri: System.get_env("SLACK_OAUTH_URL")

case System.fetch_env("OTEL_EXPORTER") do
  {:ok, "stdout"} ->
    config :opentelemetry, traces_exporter: {:otel_exporter_stdout, []}

  {:ok, "log"} ->
    config :opentelemetry, traces_exporter: {Elixir.OpenTelemetryLogExporter, [level: :warning]}

  {:ok, "honeycomb"} ->
    # Configure OpenTelemetry Exporter
    api_key = System.fetch_env!("HONEYCOMB_KEY")

    dataset =
      case config_env() do
        :test -> "pears_test"
        :dev -> "pears_dev"
        :prod -> "pears"
      end

    config(:opentelemetry, :processors, [
      {O11y.BaggageProcessor, %{}},
      otel_batch_processor: %{
        exporter: {:opentelemetry_exporter, %{}}
      }
    ])

    config :opentelemetry_exporter,
      otlp_protocol: :grpc,
      otlp_compression: :gzip,
      otlp_endpoint: "https://api.honeycomb.io:443",
      otlp_headers: [
        {"x-honeycomb-team", api_key},
        {"x-honeycomb-dataset", dataset}
      ]

  _ ->
    # Disabled by default
    config :opentelemetry, traces_exporter: :none
end
