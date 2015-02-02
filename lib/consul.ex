defmodule Consul do
  require Logger

  @server "http://localhost:8500"
  @api_version "v1"
  @datacenter "us-east-1-hub"

  def server, do: @server
  def datacenter, do: @datacenter
  def api_version, do: @api_version
  def base_uri, do: server <> "/" <> api_version

  @doc """
  Fetches and decodes JSON data from a Consul HTTP endpoint.
  """
  def get_json(url), do: get_json(url, %{})
  def get_json(url, args = %{dc: nil}), do: get_json(url, %{args | dc: datacenter})
  def get_json(url, args) do
    url <> "?" <> URI.encode_query(args)
        |> HTTPoison.get!
        |> decode_body
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
