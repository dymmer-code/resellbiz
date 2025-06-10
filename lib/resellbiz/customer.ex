defmodule Resellbiz.Customer do
  @moduledoc """
  The module is responsible for interacting with the Resellbiz API to get
  information about customers.
  """
  require Logger
  alias Resellbiz.Customer.Details
  alias Resellbiz.Customer.Search

  defp client do
    Tesla.client(middleware(), adapter())
  end

  defp middleware do
    [
      Resellbiz.Throttle,
      {Tesla.Middleware.Logger,
        format: "$method /api/customers$url?$query ===> $status / time=$time",
        log_level: :debug
      },
      {Tesla.Middleware.BaseUrl, Application.get_env(:resellbiz, :url) <> "/api/customers"},
      {Tesla.Middleware.Query,
        "auth-userid": Application.get_env(:resellbiz, :reseller_id),
        "api-key": Application.get_env(:resellbiz, :api_key)
      },
      Tesla.Middleware.JSON
    ]
  end

  defp adapter do
    {Tesla.Adapter.Finch, name: Resellbiz.Finch}
  end

  defp get(uri, opts), do: Tesla.get(client(), uri, opts)

  @default_no_of_records 25

  @doc """
  Searches for customers based on the query parameters.
  """
  def search(query_params \\ []) when is_list(query_params) do
    query_params =
      query_params
      |> Keyword.put_new(:"no-of-records", @default_no_of_records)
      |> Keyword.put_new(:"page-no", 0)

    case get("/search.json", query: query_params) do
      {:ok, response} ->
        response.body
        |> clean_result()
        |> Search.normalize()

      {:error, _} = error ->
        error
    end
  end

  defp clean_result(result) do
    Enum.reduce(result, %{"result" => []}, fn
      {_key, entry}, acc when is_map(entry) ->
        Map.update!(acc, "result", fn entries ->
          [replace_leading_key(entry, "customer.", "") | entries]
        end)

      {key, entry}, acc ->
        Map.put_new(acc, key, entry)
    end)
  end

  defp replace_leading_key(details, pattern, replacement) do
    Map.new(details, fn {key, value} ->
      {String.replace_leading(key, pattern, replacement), value}
    end)
  end

  @doc """
  Gets the details of a customer based on the username, contact ID, or query
  parameters.
  """
  def get_details(username) when is_binary(username) do
    get_details(username: username)
  end

  def get_details(contact_id) when is_integer(contact_id) do
    get_details("contact-id": contact_id)
  end

  def get_details(query_params) when is_list(query_params) do
    case get("/details.json", query: query_params) do
      {:ok, %_{status: 200} = response} ->
        Details.normalize(response.body)

      {:ok, %_{body: %{"status" => "ERROR", "message" => message}}} ->
        {:error, message}

      {:error, _} = error ->
        error
    end
  end
end
