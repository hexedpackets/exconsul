Consul
======

A wrapper around [the consul API](www.consul.io/docs/agent/http.html). Contains many convenience functions for working with the KV store.


### Configuration
There are two values that can be set to configure this library:

```elixir
# Basis for the endpoint to send HTTP requests.
config :consul, :server, "http://localhost:8500"
# Default datacenter in queries that don't specify one.
config :consul, :datacenter, "dc1"
```
