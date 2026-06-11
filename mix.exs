defmodule Pears.MixProject do
  use Mix.Project

  def project do
    [
      app: :pears,
      version: "0.1.0",
      elixir: "~> 1.16",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      releases: [
        pears: [
          applications: [opentelemetry_exporter: :permanent, opentelemetry: :temporary]
        ]
      ],
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
      extra_applications: [:logger, :runtime_tools]
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
      {:bcrypt_elixir, "~> 3.3"},
      {:cloak_ecto, "~> 1.3"},
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:dns_cluster, "~> 0.2"},
      {:fun_with_flags, "~> 1.13"},
      {:fun_with_flags_ui, "~> 1.1"},
      {:hammox, "~> 0.7"},
      {:opentelemetry_exporter, "~> 1.10"},
      {:opentelemetry, "~> 1.7"},
      {:opentelemetry_bandit, "~> 0.3"},
      {:opentelemetry_ecto, "~> 1.2"},
      {:open_telemetry_decorator, "~> 1.5"},
      {:o11y, "~> 0.3.0", override: true},
      {:opentelemetry_phoenix, "~> 2.0"},
      {:slack, "~> 0.23"},
      {:phoenix, "~> 1.8"},
      {:phoenix_ecto, "~> 4.7"},
      {:ecto_sql, "~> 3.13"},
      {:postgrex, "~> 0.22"},
      {:phoenix_html, "~> 4.3"},
      {:phoenix_live_reload, "~> 1.6", only: :dev},
      {:phoenix_live_view, "~> 1.2"},
      {:quantum, "~> 3.5"},
      {:floki, "~> 0.38", only: :test},
      {:lazy_html, "~> 0.1", only: :test},
      {:phoenix_live_dashboard, "~> 0.8"},
      {:esbuild, "~> 0.10", runtime: Mix.env() == :dev},
      {:tailwind, "~> 0.4", runtime: Mix.env() == :dev},
      {:dialyxir, "~> 1.4", only: [:dev, :test], runtime: false},
      {:heroicons,
       github: "tailwindlabs/heroicons",
       tag: "v2.2.0",
       sparse: "optimized",
       app: false,
       compile: false,
       depth: 1},
      {:swoosh, "~> 1.26"},
      {:finch, "~> 0.22"},
      {:telemetry_metrics, "~> 1.1"},
      {:telemetry_poller, "~> 1.3"},
      {:gettext, "~> 1.0"},
      {:jason, "~> 1.4"},
      {:bandit, "~> 1.12"},
      {:sentry, "~> 13.1"}
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
      setup: ["deps.get", "ecto.setup", "assets.setup", "assets.build"],
      "ecto.setup": ["ecto.create", "ecto.migrate", "run priv/repo/seeds.exs"],
      "ecto.reset": ["ecto.drop", "ecto.setup"],
      test: ["ecto.create --quiet", "ecto.migrate --quiet", "test"],
      "assets.setup": ["tailwind.install --if-missing", "esbuild.install --if-missing"],
      "assets.build": ["tailwind sample_app", "esbuild sample_app"],
      "assets.deploy": [
        "tailwind sample_app --minify",
        "esbuild sample_app --minify",
        "phx.digest"
      ]
    ]
  end
end
