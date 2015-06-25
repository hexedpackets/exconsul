defmodule Consul.Services do
  defp service_health_url(service), do: Consul.base_uri <> "/health/service/" <> service
  defp health_state_url(state), do: Consul.base_uri <> "/health/state/" <> state

  @doc """
  Returns all available services in the Consul datacenter.
  """
  def list(datacenter \\ nil), do: Consul.services(datacenter) |> Dict.keys

  @doc """
  Returns information about a service. The health endpoint is used as it returns much more detailed information
  than the catalog without losing anything.
  """
  def info(service, datacenter \\ nil), do: service_health_url(service) |> Consul.get_json(%{dc: datacenter})

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
    service_health_url(service)
    |> Consul.get_json(%{dc: datacenter})
    |> Enum.map(&(&1["Node"]))
    |> Enum.uniq
  end


  defp health_filter(service, status \\ "passing") do
    Enum.all?(service["Checks"], &(&1["Status"] == status))
  end

  @doc """
  Returns all checks in the passed in state.
  The supported states are "any", "unknown", "passing", "warning", or "critical".
  The "any" state is a wildcard that can be used to return all the checks.
  """
  def health(state, datacenter \\ nil), do: health_state_url(state) |> Consul.get_json(%{dc: datacenter})
end
