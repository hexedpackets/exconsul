defmodule Consul.ACL do
  @doc """
  Queries the policy of a given token.
  """
  def info(id) do
    [endpoint, "info", id] |> Path.join |> Consul.get_json
  end

  @doc """
  Lists all the active tokens. Requires a management token.
  """
  def list(args \\ %{}) do
    [endpoint, "list"] |> Path.join |> Consul.get_json(args)
  end

  @doc """
  Formats the Consul ACL endpoint and server into the full URL.
  """
  def endpoint, do: [Consul.base_uri, "acl"] |> Path.join
end
