defmodule Consul.Mixfile do
  use Mix.Project

  @version File.read!("VERSION") |> String.strip

  def project do
    [app: :consul,
     version: @version,
     elixir: "~> 1.0",
     deps: deps,
     name: "Consul",
     docs: [readme: "README.md", main: "README",
            source_ref: "v#{@version}",
            source_url: "https://github.com/hexedpackets/exconsul"],

     # Hex
     description: description,
     package: package]
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

  defp description do
    """
    A wrapper around the Consul API with some opinionated helper functionality.
    """
  end

  defp package do
    [contributors: ["William Huba"],
     licenses: ["Apache 2.0"],
     links: %{"GitHub" => "https://github.com/hexedpackets/exconsul"},
     files: ~w(mix.exs README.md LICENSE lib VERSION)]
  end
end
