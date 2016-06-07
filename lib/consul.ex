defmodule Consul do
  require Logger

  @api_version "v1"

  def server, do: Application.get_env(:consul, :server) || "http://localhost:8500"
  def datacenter, do: Application.get_env(:consul, :datacenter) || "dc1"
  def api_version, do: @api_version
  def base_uri, do: server <> "/" <> api_version

  defp catalog_uri(item), do: Consul.base_uri <> "/catalog/" <> item

  @doc """
  List all known datacenters.
  """
  def datacenters, do: catalog_uri("datacenters") |> get_json

  @doc """
  List all known nodes in a given datacenter. Returns a list of dicts,
  with each dict containing a "Node" and "Address" key.
  """
  def nodes(dc \\ nil), do: catalog_uri("nodes") |> get_json(%{dc: dc})

  @doc """
  List all known services in a given datacenter. The result is a Dict keyed on
  service name, and each value is a list of tags for that service.
  """
  def services(dc \\ nil), do: catalog_uri("services") |> get_json(%{dc: dc})

  @doc """
  Fetches and decodes JSON data from a Consul HTTP endpoint.
  """
  def get_json(url), do: get_json(url, %{})
  def get_json(url, args) do
    get(url, args)
    |> decode_body
  end

  def get(url), do: get(url, %{})
  def get(url, args = %{dc: nil}), do: get(url, Dict.delete(args, :dc))
  def get(url, args) do
    url <> "?" <> URI.encode_query(args)
    |> HTTPoison.get!
  end

  @doc """
  Sends a HTTP PUT request to Consul with any configured authentication.
  """
  def put(url), do: put(url, "", [])
  def put(url, value), do: put(url, "", [])
  def put(url, value, args) do
    url <> "?" <> URI.encode_query(args)
    |> HTTPoison.put!(value)
  end

  # Decodes JSON data from a HTTP response.
  defp decode_body(%{body: body}) do
    Logger.debug "Successful response: #{inspect body}"
    body |> Poison.decode |> handle_json_decode(body)
  end

  # Returns either decoded JSON data, or an empty dict.
  defp handle_json_decode({:ok, data}, _), do: data
  defp handle_json_decode({:error, _}, raw) do
    Logger.info "Unable to decode any JSON data"
    raw
  end
end
