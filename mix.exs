defmodule Pears.MixProject do
  use Mix.Project

  def project do
    [
      app: :pears,
      version: "0.1.0",
      elixir: "~> 1.7",
      elixirc_paths: elixirc_paths(Mix.env()),
      compilers: [:phoenix, :gettext] ++ Mix.compilers(),
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps()
    ]
  end

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application do
    [
      mod: {Pears.Application, []},
      extra_applications: [:logger, :runtime_tools, :os_mon, :opentelemetry]
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Specifies your project dependencies.
  #
  # Type `mix help deps` for examples and options.
  defp deps do
    [
      {:bcrypt_elixir, "~> 2.0"},
      {:cloak_ecto, "~> 1.2.0"},
      {:credo, "~> 1.4", only: [:dev, :test], runtime: false},
      {:ecto_sql, "~> 3.4"},
      {:floki, ">= 0.0.0", only: :test},
      {:fun_with_flags, "~> 1.8.1"},
      {:fun_with_flags_ui, "~> 0.7.2"},
      {:gettext, "~> 0.11"},
      {:hackney, ">= 1.11.0"},
      {:hammox, "~> 0.3"},
      {:jason, "~> 1.0"},
      {:opentelemetry, "~> 0.5.0"},
      {:opentelemetry_api, "~> 0.5.0"},
      {:open_telemetry_decorator, "~> 0.5.3"},
      {:opentelemetry_ecto,
       git: "https://github.com/opentelemetry-beam/opentelemetry_ecto.git", tag: "master"},
      {:opentelemetry_honeycomb, "~> 0.5.0-rc.1"},
      {:opentelemetry_phoenix, "~> 0.2.0"},
      {:phoenix, "~> 1.5.3"},
      {:phoenix_ecto, "~> 4.1"},
      {:phoenix_html, "~> 2.11"},
      {:phoenix_live_dashboard, "~> 0.2"},
      {:phoenix_live_reload, "~> 1.2", only: [:dev, :e2e]},
      {:phoenix_live_view, "~> 0.14.0"},
      {:plug_cowboy, "~> 2.0"},
      {:poison, ">= 1.5.0"},
      {:postgrex, ">= 0.0.0"},
      {:sentry, "~> 8.0"},
      {:slack, "~> 0.23.5"},
      {:telemetry_metrics, "~> 0.4"},
      {:telemetry_poller, "~> 0.4"},
      {:timber, "~> 3.0"},
      {:timber_ecto, "~> 2.0"},
      {:timber_exceptions, "~> 2.0"},
      {:timber_plug, "~> 1.0"}
    ]
  end

  # Aliases are shortcuts or tasks specific to the current project.
  # For example, to install project dependencies and perform other setup tasks, run:
  #
  #     $ mix setup
  #
  # See the documentation for `Mix` for more info on aliases.
  defp aliases do
    [
      setup: ["deps.get", "ecto.setup", "cmd npm install --prefix assets"],
      "ecto.setup": ["ecto.create", "ecto.migrate", "run priv/repo/seeds.exs"],
      "ecto.reset": ["ecto.drop", "ecto.setup"],
      test: ["ecto.create --quiet", "ecto.migrate --quiet", "test"]
    ]
  end
end
