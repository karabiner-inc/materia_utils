defmodule ServicexUtils.MixProject do
  use Mix.Project

  def project do
    [
      app: :servicex_utils,
      version: "0.1.1",
      elixir: "~> 1.6",
      description: "This library is a utilities for service development based on Servicex.",
      start_permanent: Mix.env() == :prod,
      package: [
        maintainers: ["tuchro yoshimura"],
        licenses: ["MIT"],
        links: %{"BitBucket" => "https://bitbucket.org/karabinertech_bi/servicex_utils/src/master/"}
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
      {:ex_doc, "~> 0.18.0", only: :dev}
    ]
  end
end
