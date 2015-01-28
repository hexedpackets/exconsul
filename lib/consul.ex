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
  def get_json(url) do
    url |> HTTPoison.get! |> decode_body
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


  defmodule KV do
    def set(value, key) do
      kv_endpoint(key) |> HTTPoison.put!(value) |> Dict.get(:body)
    end

    @doc """
    Returns the credentials stored in consul for accessing the docker registry.
    """
    def docker_credentials(datacenter \\ Consul.datacenter) do
      "secrets/docker"
          |> kv_endpoint([:raw, "dc=#{datacenter}"])
          |> Consul.get_json
    end

    def key_name(name), do: String.replace(name, "-", "/")

    @doc """
    Finds all stored configurations under a given key. Assumes they are jsonified.

    Args:
      key: The key under which Docker configs are stored.

    Returns:
      A dict of the matching keys to their configuration.
    """
    def get_conf(key) do
      kv_endpoint(key) |> _get_conf(key) |> Dict.values |> List.first
    end

    def get_conf(key, :recurse) do
      kv_endpoint(key, [:recurse]) |> _get_conf(key)
    end

    defp _get_conf(endpoint, key) do
      endpoint
          |> Consul.get_json
          |> Enum.filter(&(&1["Key"] == key || String.starts_with?(&1["Key"], key <> "/")))
          |> Enum.map(&({&1["Key"], decode_value(&1["Value"], Docker.Config)}))
          |> Enum.into %{}
    end

    defp decode_value(value, type \\ %{}) do
      b64decoded = :base64.decode(value)
      case Poison.decode(b64decoded, as: type) do
        {:ok, value} -> value
        {:error, _} -> b64decoded
      end
    end

    @doc """
    Creates or updates a configuration in the consul kv store.

    Args:
      conf: A JSONable dictionary to store.
      key: The key under which the config should be stored.
    """
    def store_json(conf, key) do
      conf |> Poison.encode! |> set(key)
    end

    @doc """
    Adds a value to an existing kv, or sets the initial value.
    This assumes the value is stored as a newline-separated set.
    """
    def append(values, key) do
      Logger.info("Appending to #{key}")
      url = kv_endpoint(key)
      _append(values, url, 0)
    end

    defp _append([], _, _), do: :ok
    defp _append(values, url, index) do
      data = Enum.join(values, "\n")
      url <> "?cas=#{index}"
          |> HTTPoison.put!(data)
          |> check_append(values, url)
    end

    defp check_append(%{body: "true"}, _, _), do: :ok
    defp check_append(%{body: "false"}, values, url) do
      Logger.debug("Unable to append values at #{url}")
      {index, current_values} = check_key(url)
      Set.union(Enum.into(current_values, HashSet.new), Enum.into(values, HashSet.new))
          |> _append(url, index)
    end

    defp check_key(url) do
      body = Consul.get_json(url) |> List.first
      index = body["ModifyIndex"]
      values = :base64.decode(body["Value"]) |> String.split("\n")
      {index, values}
    end

    @doc """
    Retrieves information about a given service.

    Args:
      service_name: The name of the service to gather information about.
      subkey: The name of the key under the service.
    Returns:
      The loaded JSON information about the service.
    """
    def service_info(name, subkey) do
      "services/#{name}/#{subkey}"
          |> kv_endpoint([:raw])
          |> Consul.get_json
    end

    @doc """
    Retrieves information under a given key, turning it into a dictionary.

    Args:
      key: The name of the key to query.
    Returns:
      A dictionary created recursively from the kv store.
    """
    def tree(key), do: _tree(key, [:recurse])
    def tree(key, datacenter), do: _tree(key, [:recurse, "dc=#{datacenter}"])
    defp _tree(key, opts) do
      prefix = key <> "/"
      kv_endpoint(key, opts)
          |> Consul.get_json
          |> Enum.filter(&(&1["Key"] != prefix && &1["Value"] != ""))
          |> Enum.map(&({String.replace(&1["Key"], prefix, ""), decode_value(&1["Value"])}))
          |> Enum.into %{}
    end



    # Formats a Consul key and remote server into the full URL.
    defp kv_endpoint(key), do: [Consul.base_uri, "kv", key] |> Enum.join("/")
    defp kv_endpoint(key, opts) do
      kv_endpoint(key) <> "?" <> Enum.join(opts, "&")
    end
  end


  defmodule Nodes do
    defp node_url(node), do: Consul.base_uri <> "/catalog/node/" <> node


    @doc """
    Looks up the IP address of a node using consul.
    """
    def address(node), do: node_url(node) |> _address
    def address(node, datacenter), do: node_url(node) <> "?dc=#{datacenter}" |> _address
    defp _address(url) do
      url |> Consul.get_json |> Dict.get("Node") |> Dict.get("Address")
    end
  end
end
