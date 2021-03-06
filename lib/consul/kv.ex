defmodule Consul.KV do
  require Logger

  @doc """
  Sets a key to the given value. Returns true if successful.
  """
  def set(value, key, args \\ %{}) do
    kv_endpoint(key) |> Consul.put(value, args)
  end

  @doc """
  Retrieves a key from Cosnul.
  """
  def get(key, args \\ %{}) do
    key |> kv_endpoint |> Consul.get(args)
  end

  @doc """
  Gets a key in raw format and returns the value.
  """
  def get_raw(key, args \\ %{}) do
    get(key, Map.put(args, :raw, nil))
  end

  @doc """
  Gets a key containing newline-deliminated values, splitting them into a list.
  """
  def get_list(key, args \\ %{}) do
    get_raw(key, args)
    |> String.split("\n")
  end

  @doc """
  Deletes a key.
  """
  def delete(key) do
    kv_endpoint(key) |> Consul.delete
  end

  @doc """
  Deletes all keys that start with a given prefix.
  """
  def delete(key, :recurse) do
    kv_endpoint(key) |> Consul.delete(%{recurse: nil})
  end

  @doc """
  Returns the credentials stored in consul for accessing the docker registry.
  """
  def docker_credentials(registry) do
    "secrets/docker/" <> registry
    |> kv_endpoint
    |> Consul.get_json(%{dc: Consul.datacenter, raw: nil})
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
    kv_endpoint(key) |> _get_conf(key, %{dc: datacenter}) |> Map.values |> List.first
  end

  def get_conf(key, :recurse, datacenter) do
    kv_endpoint(key) |> _get_conf(key, %{dc: datacenter, recurse: nil})
  end

  defp _get_conf(endpoint, key, opts) do
    endpoint
    |> Consul.get_json(opts)
    |> Enum.filter(&(&1["Key"] == key || String.starts_with?(&1["Key"], key <> "/")))
    |> Enum.map(&({&1["Key"], decode_value(&1["Value"], Docker.Config)}))
    |> Enum.into(%{})
  end

  @doc """
  Takes a value as returned by Consul (base-64 encoded) and decodes it.
  If the data looks JSON-y, the JSON data will also be decoded.
  """
  def decode_value(value), do: decode_value(value, %{})
  def decode_value(nil, _type), do: nil
  def decode_value(value, type) do
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
  def append(values, key, datacenter \\ nil) do
    Logger.info("Appending to #{key}")
    url = kv_endpoint(key)
    _append(values, url, %{dc: datacenter}, 0)
  end

  defp _append([], _url, _args, _index), do: :ok
  defp _append(values, url, args, index) do
    data = Enum.join(values, "\n")

    Consul.put(url, data, [cas: index, dc: args.dc])
    |> check_append(values, url, args)
  end

  defp check_append("true", _values, _url, _args), do: :ok
  defp check_append("false", values, url, args) do
    Logger.debug("Unable to append values at #{url}")
    {index, current_values} = check_key(url, args)

    MapSet.union(Enum.into(current_values, MapSet.new), Enum.into(values, MapSet.new))
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
  def tree(key), do: tree(key, %{})
  def tree(key, datacenter) when is_binary(datacenter), do: tree(key, %{dc: datacenter})
  def tree(key, args) do
    args = Map.put(args, :recurse, nil)

    prefix = key <> "/"
    kv_endpoint(key)
    |> Consul.get_json(args)
    |> Enum.filter(&(&1["Key"] != prefix && &1["Value"] != ""))
    |> Enum.map(&({String.replace(&1["Key"], prefix, ""), decode_value(&1["Value"])}))
    |> Enum.into(%{})
  end

  @doc """
  List the keys under a given prefix.
  """
  def keys(prefix), do: keys(prefix, %{})
  def keys(prefix, sep) when is_binary(sep), do: keys(prefix, %{seperator: sep})
  def keys(prefix, args) do
    args = Map.put(args, :keys, nil)
    kv_endpoint(prefix) <> "/"
    |> Consul.get_json(args)
  end


  @doc """
  Formats a Consul key and remote server into the full URL.
  """
  def kv_endpoint(key), do: [Consul.base_uri, "kv", key] |> Path.join
end
