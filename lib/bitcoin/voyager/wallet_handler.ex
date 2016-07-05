defmodule Bitcoin.Voyager.WalletHandler do
  alias Bitcoin.Voyager.WalletFSM
  alias Bitcoin.Voyager.Util

  @moduledoc """
  Base module for building Cowboy handlers
  """
  def init(req, _opts) do
    case transform_args(req) do
      %{addresses: addresses, page: page, per_page: per_page} ->
        addresses = String.split(addresses, ",")
        {:ok, fsm} = WalletFSM.start_link(addresses, page, per_page, self)
        {:cowboy_loop, req, %{fsm: fsm}, 5000}
      _ ->
        {:ok, json} = JSX.encode(%{status: :fail, message: :arguement_error})
        {:ok, json} = JSX.prettify(json)
        {:ok, req} = :cowboy_req.reply(400, [], json, req)
        {:shutdown, req, nil}
    end
  end

  def info({:wallet, wallet}, req, state) do
    {:ok, json} = JSX.encode(%{status: :success, data: wallet})
    {:ok, json} = JSX.prettify(json)
    {:ok, req} = :cowboy_req.reply(200, [], json, req)
    {:ok, req, state}
  end

  def transform_args(req) do
    :cowboy_req.parse_qs(req)
      |> Enum.into(%{"page" => 0, "per_page" => 20})
      |> Util.atomify
  end

  def terminate(_reason, _req, _state) do
    :ok
  end

  def to_integer(int) when is_integer(int), do: int
  def to_integer(string) when is_binary(string) do
    String.to_integer(string)
  end

end