defmodule Commander.MixProject do
  use Mix.Project

  def project do
    [
      app: :commander,
      version: "0.1.1",
      elixir: "~> 1.16",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      releases: [
        commander: [
          cookie: "secret-cookie-value",
          include_erts: true,
          include_executables_for: [:unix],
          applications: [commander: :permanent, runtime_tools: :permanent],
          steps: [:assemble, :tar]
        ]
      ]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {Commander.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:muontrap, "~> 1.5"}
    ]
  end
end
