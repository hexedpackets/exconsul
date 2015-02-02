defmodule Consul.Services do
  defp service_url(service), do: Consul.base_uri <> "/catalog/service/" <> service

  @doc """
  Returns all available services in the Consul datacenter. The result is a Dict keyed on
  service name, and each value is a list of tags for that service.
  """
  def list(datacenter \\ nil), do: Consul.base_uri <> "/catalog/services" |> Consul.get_json(%{dc: datacenter})

  def info(service, datacenter \\ nil), do: service_url(service) |> Consul.get_json(%{dc: datacenter})

  @doc """
  Looks up healthy nodes running a particular service
  """
  def nodes(service, :passing), do: nodes(service, :passing, nil)
  def nodes(service, :passing, datacenter) do
    Consul.base_uri <> "/health/service/" <> service
        |> Consul.get_json(%{dc: datacenter})
        |> Enum.filter(&health_filter/1)
        |> Enum.map(&(&1["Node"]["Node"]))
        |> Enum.uniq
  end

  @doc """
  Looks up all nodes running a particular service.
  """
  def nodes(service), do: nodes(service, nil)
  def nodes(service, datacenter) do
    service_url(service)
        |> Consul.get_json(%{dc: datacenter})
        |> Enum.map(&(&1["Node"]))
        |> Enum.uniq
  end


  defp health_filter(service, status \\ "passing") do
    Enum.all?(service["Checks"], &(&1["Status"] == status))
  end
end
