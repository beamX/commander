defmodule Commander.MixProject do
  use Mix.Project

  def project do
    [
      app: :commander,
      version: version(Mix.env()),
      elixir: "~> 1.17",
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

  def version(:dev), do: "0.1.0"

  def version(_) do
    release_vsn = System.get_env("MIX_RELEASE_VSN")

    if !release_vsn do
      raise """
      environment variable MIX_RELEASE_VSN is required but not set
      """
    end

    release_vsn
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
      {:erlexec, "~> 2.0"}
    ]
  end
end
