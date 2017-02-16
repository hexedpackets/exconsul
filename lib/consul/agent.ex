defmodule Consul.Agent do
  @moduledoc """
  Module for working with the agent HTTP endpoint.

  https://www.consul.io/docs/agent/http/agent.html
  """
  require Logger

  @doc """
  Finds all service IDs for a given service name. A given service can be
  running multiple times on the agent with different IDs.
  """
  def service_ids(service) do
    services()
    |> Stream.filter(fn({_id, %{"Service" => name}}) -> name == service end)
    |> Enum.map(fn({id, _}) -> id end)
  end

  @doc """
  Finds all services running on this agent.
  """
  def services do
    base_url() <> "/services"
    |> Consul.get_json
  end

  @doc """
  Enables maintenance mode for a service by setting a failing health check
  identical to `consul main -enable`.
  """
  def service_maint_enable(service) do
    Logger.info "Enabling maintenance mode for #{service}"
    maintenance_url(service)
    |> Consul.put("", %{enable: true})
  end
  def service_maint_enable(service, reason) do
    Logger.info "Enabling maintenance mode for #{service}: #{reason}"
    maintenance_url(service)
    |> Consul.put("", %{enable: true, reason: reason})
  end

  @doc """
  Disables maintance mode for a service.
  """
  def service_maint_disable(service) do
    Logger.info "Disabling maintenance mode for #{service}"
    maintenance_url(service)
    |> Consul.put("", %{enable: false})
  end

  defp base_url, do: Consul.base_uri() <> "/agent"
  defp service_url, do: base_url() <> "/service"
  defp maintenance_url(service), do: service_url() <> "/maintenance/" <> service
end
