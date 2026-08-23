defmodule Resellbiz.Contact do
  @moduledoc """
  This module is responsible for handling the contact information of the
  reseller's customers. It provides functions to search, add, and get details
  of a contact.
  """
  require Logger
  alias Resellbiz.Contact.Action
  alias Resellbiz.Contact.Add
  alias Resellbiz.Contact.Details
  alias Resellbiz.Contact.Search

  defp client, do: Resellbiz.Client.new("/api/contacts")

  defp get(uri, opts), do: Req.get(client(), request_opts(uri, opts))

  defp post(uri, body, opts),
    do: Req.post(client(), Keyword.put(request_opts(uri, opts), :body, body))

  # Every call site in this module passes its extra query params as `query:`
  # (the Tesla-era name) -- translated here to Req's `params:` option so none
  # of them needed to change when this module moved off Tesla.
  defp request_opts(uri, opts) do
    {query, opts} = Keyword.pop(opts, :query, [])
    Keyword.merge(opts, url: uri, params: query)
  end

  @default_no_of_records 25

  @doc """
  Searches for contacts based on the query parameters provided.
  """
  def search(query_params \\ []) when is_list(query_params) do
    customer_id = Application.get_env(:resellbiz, :customer_id)

    query_params =
      query_params
      |> Keyword.put(:"customer-id", customer_id)
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
    Map.update!(result, "result", fn result ->
      for entry <- result do
        Map.new(entry, fn {key, value} ->
          {key
           |> String.replace_leading("contact.", "")
           |> String.replace_leading("entity.", ""), value}
        end)
      end
    end)
  end

  @doc """
  Fetches the details of a contact based on the contact ID provided.
  """
  def get_details(contact_id) when is_integer(contact_id) do
    case get("/details.json", query: ["contact-id": contact_id]) do
      {:ok, %_{status: 200} = response} ->
        response.body
        |> Details.normalize()

      {:ok, %_{body: %{"status" => "ERROR", "message" => message}}} ->
        {:error, message}

      {:error, _} = error ->
        error
    end
  end

  @doc """
  Adds a new contact based on the parameters provided.
  """
  def add(params) when is_map(params) and not is_struct(params) do
    changeset = Add.changeset(params)

    with {:ok, params} <- Add.to_params(changeset),
         params = Enum.reject(params, fn {_key, value} -> is_nil(value) end),
         {:ok, %_{status: 200} = response} <- post("/add.json", "", query: params),
         contact_id when is_integer(contact_id) <- response.body do
      {:ok, contact_id}
    else
      {:ok, %_{status: status}} when status != 200 ->
        {:error, "Server error"}

      %{"status" => "ERROR", "message" => message} ->
        {:error, message}

      {:error, _} = error ->
        error
    end
  end

  @doc """
  Delete a contact given the contact ID.
  """
  def delete(contact_id) when is_integer(contact_id) do
    case post("/delete.json", "", query: ["contact-id": contact_id]) do
      {:ok, %_{status: 200, body: %{"eaqid" => _}} = response} ->
        {:ok, Action.normalize(response.body)}

      {:ok, %_{body: %{"status" => "ERROR", "message" => message}}} ->
        {:error, message}

      {:ok, %_{body: %{"status" => "error", "error" => message}}} ->
        {:error, message}

      {:error, _} = error ->
        error
    end
  end
end
