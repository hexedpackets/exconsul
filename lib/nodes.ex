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
    node_url(node) |> Consul.get_json(%{dc: datacenter})
  end
end
