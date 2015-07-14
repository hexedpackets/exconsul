defmodule Consul.Mixfile do
  use Mix.Project

  def project do
    [app: :consul,
     version: "0.1.1",
     elixir: "~> 1.0",
     deps: deps]
  end

  def application do
    [applications: [:logger, :httpoison, :poison]]
  end

  defp deps do
    [
      {:poison, "~> 1.2"},
      {:httpoison, "~> 0.5"}
    ]
  end
end
