defmodule MateriaUtils.MixProject do
  use Mix.Project

  def project do
    [
      app: :materia_utils,
      version: "0.1.1",
      elixir: "~> 1.6",
      test_coverage: [tool: ExCoveralls, ignore_modules: [MateriaUtils.Ecto.EctoUtil]],
      preferred_cli_env: [coveralls: :test, "coveralls.detail": :test, "coveralls.post": :test, "coveralls.html": :test],
      description: "This library is a utilities for service development based on Materia.",
      start_permanent: Mix.env() == :prod,
      package: [
        maintainers: ["karabiner.inc"],
        licenses: ["MIT"],
        links: %{"BitBucket" => "https://github.com/karabiner-inc/materia_utils"}
      ],
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      # {:dep_from_hexpm, "~> 0.3.0"},
      # {:dep_from_git, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"},
      {:ecto, "~> 2.2"},
      {:poison, "~> 3.0"},
      {:timex, "~> 3.3"},
      {:mojiex, "~> 0.1.0"},
      {:ex_doc, "~> 0.18.0", only: :dev},
      # {:coverex, "~> 1.5"},
      {:excoveralls, "~> 0.10", only: :test},
      {:credo, "~> 1.0.0", only: [:dev, :test], runtime: false}
    ]
  end
end
