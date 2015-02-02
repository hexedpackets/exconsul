defmodule Consul.Services do
  defp service_url(service), do: Consul.base_uri <> "/catalog/service/" <> service

  def info(service), do: service_url(service) |> Consul.get_json

  @doc """
  Looks up all nodes running a particular service.
  """
  def nodes(service) do
    service_url(service)
        |> Consul.get_json
        |> Enum.map(&(&1["Node"]))
        |> Enum.uniq
  end

  @doc """
  Looks up healthy nodes running a particular service
  """
  def nodes(service, :passing) do
    Consul.base_uri <> "/health/service/" <> service
        |> Consul.get_json
        |> Enum.filter(&health_filter/1)
        |> Enum.map(&(&1["Node"]["Node"]))
        |> Enum.uniq
  end

  defp health_filter(service, status \\ "passing") do
    Enum.all?(service["Checks"], &(&1["Status"] == status))
  end
end
