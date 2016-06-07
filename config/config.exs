use Mix.Config

config :consul, :server, "http://localhost:8500"
config :consul, :datacenter, "dc1"

config :consul, :token, System.get_env("CONSUL_TOKEN")
