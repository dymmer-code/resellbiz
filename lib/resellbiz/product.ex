defmodule Resellbiz.Product do
  @moduledoc """
  The product module is responsible for fetching the product details and prices
  from the Resellbiz API.
  """
  use Tesla
  require Logger
  alias Resellbiz.Product.Details
  alias Resellbiz.Product.Prices

  plug(Resellbiz.Throttle)

  plug(
    Tesla.Middleware.BaseUrl,
    Application.get_env(:resellbiz, :url) <> "/api/products/"
  )

  plug(Tesla.Middleware.Query,
    "auth-userid": Application.get_env(:resellbiz, :reseller_id),
    "api-key": Application.get_env(:resellbiz, :api_key)
  )

  plug(Tesla.Middleware.JSON)

  @doc """
  Fetches the product details from the Resellbiz API.
  """
  def list_product_details do
    case get("/details.json") do
      {:ok, response} ->
        response.body
        |> Stream.map(fn {key, value} -> is_map(value) && Map.put(value, "id", key) end)
        |> Stream.filter(&(is_map(&1) and is_map_key(&1, "tldlist")))
        |> Enum.map(&Details.normalize/1)

      {:error, _} = error ->
        error
    end
  end

  @doc """
  Fetches the product prices from the Resellbiz API.
  """
  def list_product_reseller_cost_prices do
    case get("/reseller-cost-price.json") do
      {:ok, response} ->
        for {name, %{"addnewdomain" => _, "addtransferdomain" => _} = product} <- response.body do
          product
          |> Map.put("id", name)
          |> Map.new(&remove_index/1)
          |> Prices.normalize()
        end

      {:error, _} = error ->
        error
    end
  end

  defp remove_index({key, %{"1" => value}}), do: {key, value}
  defp remove_index({"id", value}), do: {"id", value}
end
