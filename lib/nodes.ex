defmodule Consul.Nodes do
  defp node_url(node), do: Consul.base_uri <> "/catalog/node/" <> node


  @doc """
  Looks up the IP address of a node using consul.
  """
  def address(node), do: node_url(node) |> _address
  def address(node, datacenter), do: node_url(node) <> "?dc=#{datacenter}" |> _address
  defp _address(url) do
    url |> Consul.get_json |> Dict.get("Node") |> Dict.get("Address")
  end

  def info(node) do
    node_url(node) |> Consul.get_json
  end
end
