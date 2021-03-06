defmodule Blogit.Mixfile do
  use Mix.Project

  @version "1.0.1"

  def project do
    [app: :blogit,
     version: @version,
     elixir: "~> 1.4",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     docs: [
       extras: ["README.md"], main: "readme", source_ref: "v#{@version}",
       source_url: "https://github.com/meddle0x53/blogit"
     ],
     description: """
       Blogit is an OTP application for generating blog posts from a git
       repository containing markdown files.
     """,
     package: package(),
     aliases: aliases(),
     deps: deps()]
  end

  def application do
    [applications: [:logger, :yaml_elixir],
     mod: {Blogit, []}]
  end

  defp deps do
    [
      {:git_cli, "~> 0.2"},
      {:earmark, "~> 1.1"},
      {:yaml_elixir, "~> 1.3.0"},
      {:calendar, "~> 0.16.1"},
      {:ex_doc, ">= 0.15.0", only: :dev},
      {:dialyxir, "~> 0.5", only: [:dev], runtime: false}
    ]
  end

  defp package do
    %{
      licenses: ["MIT"],
      maintainers: ["Nikolay Tsvetinov (Meddle)"],
      links: %{"GitHub" => "https://github.com/meddle0x53/blogit"}
    }
  end

  defp aliases do
    [test: "test --no-start"]
  end
end
