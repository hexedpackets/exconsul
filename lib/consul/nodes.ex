defmodule Consul.Nodes do
  defp node_url(node), do: Consul.base_uri <> "/catalog/node/" <> node

  @doc """
  List all known nodes in a given datacenter. Returns a list of node names.
  """
  def list(datacenter \\ nil), do: Consul.nodes(datacenter) |> Enum.map(&(&1["Node"]))

  @doc """
  Looks up the IP address of a node using consul.
  """
  def address(node), do: node_url(node) |> _address(%{})
  def address(node, datacenter), do: node_url(node) |> _address(%{dc: datacenter})
  defp _address(url, opts) do
    url |> Consul.get_json(opts) |> Map.get("Node") |> Map.get("Address")
  end

  def info(node, datacenter \\ nil) do
    health_data = health(node, datacenter)
    node_url(node)
    |> Consul.get_json(%{dc: datacenter})
    |> Map.put("Health", health_data)
  end

  @doc """
  Returns the health info of a node.
  """
  def health(node, datacenter \\ nil) do
    Consul.base_uri <> "/health/node/" <> node |> Consul.get_json(%{dc: datacenter})
  end
end
