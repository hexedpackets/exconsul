defmodule Consul.Session do
  require Logger

  def endpoint, do: [Consul.base_uri, "session"] |> Path.join

  @doc """
  Creates a new session and returns the session ID.
  """
  def create, do: create(%{})
  def create(name, ttl, behaviour), do: create(%{"Name" => name, "TTL" => ttl, "Behavior" => behaviour})
  def create(request = %{}), do: Poison.encode!(request) |> create
  def create(request) do
    endpoint() <> "/create"
    |> Consul.put(request)
    |> Consul.decode_body
    |> Map.get("ID")
  end

  @doc """
  Destroys a given session.
  """
  def destroy(session) do
    endpoint() <> "/destroy/" <> session
    |> Consul.put
  end

  @doc """
  Queries a given session.
  """
  def info(session) do
    endpoint() <> "/info/" <> session
    |> Consul.get
    |> Consul.decode_body
  end

  @doc """
  Lists sessions belonging to a node.
  """
  def node(node) do
    endpoint() <> "/node/" <> node
    |> Consul.get
    |> Consul.decode_body
  end

  @doc """
  Lists all active sessions.
  """
  def list do
    endpoint() <> "/list"
    |> Consul.get
    |> Consul.decode_body
  end

  @doc """
  Renews a TTL-based session.
  """
  def renew(session) do
    endpoint() <> "/renew/" <> session
    |> Consul.put
    |> Consul.decode_body
  end
end
