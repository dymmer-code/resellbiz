defmodule Resellbiz.Product do
  @moduledoc """
  The product module is responsible for fetching the product details and prices
  from the Resellbiz API.
  """
  require Logger
  alias Resellbiz.Product.Cache
  alias Resellbiz.Product.Details
  alias Resellbiz.Product.Prices

  defp client, do: Resellbiz.Client.new("/api/products")

  defp get(uri), do: Req.get(client(), url: uri)

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

  @doc """
  Fetches the flat (not per-TLD) reseller cost of WHOIS Privacy Protection,
  in USD. It lives as a top-level `"privacy_protection"` key in
  `reseller-cost-price.json`, alongside the per-TLD product entries
  `list_product_reseller_cost_prices/0` reads -- same rate regardless of
  which TLD (see `Resellbiz.Product.Details.privacy_protection_allowed?/0`
  for which TLDs support privacy protection at all).
  """
  def list_privacy_protection_cost do
    case get("/reseller-cost-price.json") do
      {:ok, response} ->
        case response.body["privacy_protection"] do
          nil -> {:error, :not_found}
          value -> {:ok, Decimal.new(value)}
        end

      {:error, _} = error ->
        error
    end
  end

  @doc """
  Perform a local search of the details requested for the TLD.
  This function uses `Resellbiz.Product.Cache` for ensuring the data is always
  available locally.
  """
  defdelegate get_details_by_tld(tld), to: Cache

  @doc """
  Performs a local search of the prices requested for the TLD.
  This function uses `Resellbiz.Product.Cache` for ensuring the data is always
  available locally.
  """
  defdelegate get_prices_by_tld(tld), to: Cache

  @doc """
  Cached WHOIS Privacy Protection reseller cost -- see
  `list_privacy_protection_cost/0` for where the value comes from.
  """
  defdelegate get_privacy_protection_cost(), to: Cache
end
