defmodule Rs.MixProject do
  use Mix.Project

  def project do
    [
      app: :rs,
      version: "0.1.0",
      elixir: "~> 1.15",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps(),
      compilers: [:phoenix_live_view] ++ Mix.compilers(),
      listeners: [Phoenix.CodeReloader]
    ]
  end

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application do
    [
      mod: {Rs.Application, []},
      extra_applications: [:logger, :runtime_tools]
    ]
  end

  def cli do
    [
      preferred_envs: [precommit: :test]
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
      {:bandit, "~> 1.5"},
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:dns_cluster, "~> 0.2.0"},
      {:ecto_sql, "~> 3.13"},
      {:esbuild, "~> 0.10", runtime: Mix.env() == :dev},
      {:floki, "~> 0.38.0"},
      {:gettext, "~> 0.26"},
      {:heroicons,
       github: "tailwindlabs/heroicons", tag: "v2.2.0", sparse: "optimized", app: false, compile: false, depth: 1},
      {:jason, "~> 1.2"},
      # {:journey, github: "markmark206/journey", branch: "main"},
      {:journey, "~> 0.10.37"},
      {:lazy_html, ">= 0.1.0", only: :test},
      {:nanoid, "~> 2.1.0"},
      {:phoenix, "~> 1.8.1"},
      {:phoenix_ecto, "~> 4.5"},
      {:phoenix_html, "~> 4.1"},
      {:phoenix_live_dashboard, "~> 0.8.3"},
      {:phoenix_live_reload, "~> 1.2", only: :dev},
      {:phoenix_live_view, "~> 1.1.0"},
      {:postgrex, ">= 0.0.0"},
      {:req, "~> 0.5"},
      {:swoosh, "~> 1.16"},
      {:tailwind, "~> 0.3", runtime: Mix.env() == :dev},
      {:telemetry_metrics, "~> 1.0"},
      {:telemetry_poller, "~> 1.0"},
      {:tzdata, "~> 1.1"}
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
      "ecto.setup": [
        "ecto.create -r Journey.Repo -r Rs.Repo",
        "ecto.migrate -r Journey.Repo -r Rs.Repo",
        "run priv/repo/seeds.exs"
      ],
      "ecto.reset": ["ecto.drop -r Journey.Repo -r Rs.Repo", "ecto.setup"],
      test: ["ecto.create --quiet", "ecto.migrate --quiet", "test"],
      "assets.setup": ["tailwind.install --if-missing", "esbuild.install --if-missing"],
      "assets.build": ["compile", "tailwind rs", "esbuild rs"],
      "assets.deploy": [
        "tailwind rs --minify",
        "esbuild rs --minify",
        "phx.digest"
      ],
      precommit: ["compile --warning-as-errors", "deps.unlock --unused", "format", "credo", "test"]
    ]
  end
end
