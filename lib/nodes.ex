defmodule Consul.Nodes do
  defp node_url(node), do: Consul.base_uri <> "/catalog/node/" <> node

  @doc """
  Looks up the IP address of a node using consul.
  """
  def address(node), do: node_url(node) |> _address(%{})
  def address(node, datacenter), do: node_url(node) |> _address(%{dc: datacenter})
  defp _address(url, opts) do
    url |> Consul.get_json(opts) |> Dict.get("Node") |> Dict.get("Address")
  end

  def info(node, datacenter \\ nil) do
    health_data = health(node, datacenter)
    node_url(node)
        |> Consul.get_json(%{dc: datacenter})
        |> Dict.put("Health", health_data)
  end

  @doc """
  Returns the health info of a node.
  """
  def health(node, datacenter \\ nil) do
    Consul.base_uri <> "/health/node/" <> node |> Consul.get_json(%{dc: datacenter})
  end
end
