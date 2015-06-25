defmodule Consul.Agent do
  @moduledoc """
  Module for working with the agent HTTP endpoint.

  https://www.consul.io/docs/agent/http/agent.html
  """
  require Logger

  @maintenance_message "Maintenance mode is enabled for this service, but no reason was provided. This is a default message."

  @doc """
  Enables maintenance mode for a service by setting a failing health check
  identical to `consul main -enable`.
  """
  def service_maint_enable(service) do
    Logger.info "Enabling maintenance mode for #{service}"
    maintenance_url(service) <> "?" <> URI.encode_query(%{enable: true})
    |> HTTPoison.put!("")
  end
  def service_maint_enable(service, reason) do
    Logger.info "Enabling maintenance mode for #{service}: #{reason}"
    maintenance_url(service) <> "?" <> URI.encode_query(%{enable: true, reason: reason})
    |> HTTPoison.put!("")
  end

  @doc """
  Disables maintance mode for a service.
  """
  def service_maint_disable(service) do
    Logger.info "Disabling maintenance mode for #{service}"
    maintenance_url(service) <> "?" <> URI.encode_query(%{enable: false})
    |> HTTPoison.put!("")
  end

  defp base_url, do: Consul.base_uri <> "/agent"
  defp service_url, do: base_url <> "/service"
  def maintenance_url(service), do: service_url <> "/maintenance/" <> service
end
