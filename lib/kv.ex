defmodule Consul.KV do
  require Logger

  def set(value, key) do
    %HTTPoison.Response{body: body} = kv_endpoint(key) |> HTTPoison.put!(value)
    body
  end

  @doc """
  Returns the credentials stored in consul for accessing the docker registry.
  """
  def docker_credentials(datacenter \\ Consul.datacenter) do
    "secrets/docker"
        |> kv_endpoint
        |> Consul.get_json(%{dc: datacenter, raw: nil})
  end

  def key_name(name), do: String.replace(name, "-", "/")

  @doc """
  Finds all stored configurations under a given key. Assumes they are jsonified.

  Args:
    key: The key under which Docker configs are stored.

  Returns:
    A dict of the matching keys to their configuration.
  """
  def get_conf(key), do: get_conf(key, nil)
  def get_conf(key, :recurse), do: get_conf(key, :recurse, nil)

  def get_conf(key, datacenter) do
    kv_endpoint(key) |> _get_conf(key, %{dc: datacenter}) |> Dict.values |> List.first
  end

  def get_conf(key, :recurse, datacenter) do
    kv_endpoint(key) |> _get_conf(key, %{dc: datacenter, recurse: nil})
  end

  defp _get_conf(endpoint, key, opts) do
    endpoint
        |> Consul.get_json(opts)
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
  def append(values, key, datacenter \\ Consul.datacenter) do
    Logger.info("Appending to #{key}")
    url = kv_endpoint(key)
    _append(values, url, %{dc: datacenter}, 0)
  end

  defp _append([], _url, _args, _index), do: :ok
  defp _append(values, url, args, index) do
    data = Enum.join(values, "\n")
    url <> "?" <> URI.encode_query([cas: index, dc: args.datacenter])
        |> HTTPoison.put!(data)
        |> check_append(values, url, args)
  end

  defp check_append(%{body: "true"}, _values, _url, _args), do: :ok
  defp check_append(%{body: "false"}, values, url, args) do
    Logger.debug("Unable to append values at #{url}")
    {index, current_values} = check_key(url, args)
    Set.union(Enum.into(current_values, HashSet.new), Enum.into(values, HashSet.new))
        |> _append(url, args, index)
  end

  defp check_key(url, args) do
    body = Consul.get_json(url, args) |> List.first
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
  def service_info(name, subkey, datacenter \\ nil) do
    "services/#{name}/#{subkey}"
        |> kv_endpoint
        |> Consul.get_json(%{dc: datacenter, raw: nil})
  end

  @doc """
  Retrieves information under a given key, turning it into a dictionary.

  Args:
    key: The name of the key to query.
  Returns:
    A dictionary created recursively from the kv store.
  """
  def tree(key, datacenter \\ nil), do: _tree(key, %{recurse: nil, dc: datacenter})
  defp _tree(key, args) do
    prefix = key <> "/"
    kv_endpoint(key)
        |> Consul.get_json(args)
        |> Enum.filter(&(&1["Key"] != prefix && &1["Value"] != ""))
        |> Enum.map(&({String.replace(&1["Key"], prefix, ""), decode_value(&1["Value"])}))
        |> Enum.into %{}
  end


  # Formats a Consul key and remote server into the full URL.
  def kv_endpoint(key), do: [Consul.base_uri, "kv", key] |> Path.join
end
