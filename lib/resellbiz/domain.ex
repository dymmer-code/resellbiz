defmodule Resellbiz.Domain do
  @moduledoc """
  The `Resellbiz.Domain` module is responsible for interacting with the
  Resellbiz API to check the status of a domain, register a domain,
  transfer a domain, delete a domain, and retrieve the price of a domain.
  """
  use Tesla, only: [:get, :post], docs: false
  require Logger
  alias Resellbiz.Domain.Action
  alias Resellbiz.Domain.Check
  alias Resellbiz.Domain.Register
  alias Resellbiz.Domain.Transfer
  alias Resellbiz.Product.Cache, as: ProductCache

  @default_no_of_records 25

  plug(Resellbiz.Throttle)

  plug(Tesla.Middleware.Logger,
    format: "$method /api/domains$url?$query ===> $status / time=$time",
    log_level: :debug
  )

  plug(Tesla.Middleware.BaseUrl, Application.get_env(:resellbiz, :url) <> "/api/domains/")

  plug(Tesla.Middleware.Query,
    "auth-userid": Application.get_env(:resellbiz, :reseller_id),
    "api-key": Application.get_env(:resellbiz, :api_key)
  )

  plug(Tesla.Middleware.JSON)

  defp domain_to_query(domain) do
    [basename, tld] = String.split(domain, ".", parts: 2)
    ["domain-name": basename, tlds: tld]
  end

  @doc """
  Retrieve the status of a domain. The status could be one of the following:

  - `:available` if the domain is available for registration.
  - `:registered_through_us` if the domain is registered through but belongs
    to another user.
  - `:registered_through_others` if the domain is registered through another
    registrar.
  - `:unknown` if the status of the domain is unknown. This could happen if
    the service is unable to connect to the TLDs to determine the status of
    the domain.
  """
  def domain_status(domain) when is_binary(domain) do
    domain
    |> domain_to_query()
    |> domain_status()
  end

  def domain_status(domain_query) when is_list(domain_query) do
    case get("/available.json", query: domain_query) do
      {:ok, response} ->
        response.body
        |> Enum.map(fn {key, value} -> Map.put(value, "domain", key) end)
        |> Enum.map(&Check.normalize/1)

      {:error, _} = error ->
        error
    end
  end

  @doc """
  Check if a domain is available for registration.
  """
  def available?(domain) when is_binary(domain) do
    case domain_status(domain) do
      [%Check{domain: ^domain, status: :available} = response] ->
        Logger.debug("response (ok) => #{inspect(response)}")
        true

      [%Check{domain: ^domain} = response] ->
        Logger.debug("response (ok) => #{inspect(response)}")
        false

      {:error, _} = error ->
        Logger.debug("response (error) => #{inspect(error)}")
        false
    end
  end

  def transfer(_name, _authcode, _years, _ns, contacts)
      when not is_list(contacts) or length(contacts) != 4 do
    {:error, :invalid_contacts}
  end

  def transfer(name, authcode, ns, [owner, admin, tech, billing] = _contacts) do
    with [_base_domain, tld] <- String.split(name, ".", parts: 2),
         {:ok, details} <- ProductCache.get_details_by_tld(tld) do
      %{
        name: name,
        authcode: authcode,
        ns: ns,
        customer_id: Application.get_env(:resellbiz, :customer_id),
        owner_contact_id: owner,
        admin_contact_id: admin,
        tech_contact_id: tech,
        billing_contact_id: billing
      }
      |> Transfer.changeset(details)
      |> case do
        {:ok, query_params} ->
          do_transfer(query_params)

        {:error, _} = error ->
          error
      end
    else
      _ -> {:error, :invalid_domain_name}
    end
  end

  defp do_transfer(query_params) do
    case post("/transfer.json", "", query: query_params) do
      {:ok, %_{status: 200, body: %{"actionstatus" => _}} = response} ->
        {:ok, Action.normalize(response.body)}

      {:ok, %_{body: %{"status" => "ERROR", "message" => message}}} ->
        {:error, message}

      {:ok, %_{body: %{"status" => "error", "error" => message}}} ->
        {:error, message}

      {:error, _} = error ->
        error
    end
  end

  @doc """
  Register a domain. The domain name should be in the format `name.tld`.
  The years should be the number of years the domain should be registered for,
  depending on the TLD the number of the years could be between 1 and 10 or it
  could required 2 or more years as minimum registration period.

  The NS should be a list of nameservers in the format `["ns1.example.com",
  "ns2.example.com"]`. Most of the TLD require at least 2 nameservers.

  The contacts should be a list of 4 contacts in the following order:

  - Owner. The owner of the domain.
  - Admin. The administrative contact for the domain.
  - Tech. The technical contact for the domain.
  - Billing. The contact for billing purposes.
  """
  def register(_name, _years, _ns, contacts)
      when not is_list(contacts) or length(contacts) != 4 do
    {:error, :invalid_contacts}
  end

  def register(name, years, ns, [owner, admin, tech, billing] = _contacts) do
    with [_base_domain, tld] <- String.split(name, ".", parts: 2),
         {:ok, details} <- ProductCache.get_details_by_tld(tld) do
      %{
        name: name,
        years: years,
        ns: ns,
        customer_id: Application.get_env(:resellbiz, :customer_id),
        owner_contact_id: owner,
        admin_contact_id: admin,
        tech_contact_id: tech,
        billing_contact_id: billing
      }
      |> Register.changeset(details)
      |> case do
        {:ok, query_params} ->
          do_register(query_params)

        {:error, _} = error ->
          error
      end
    else
      _ -> {:error, :invalid_domain_name}
    end
  end

  defp do_register(query_params) do
    case post("/register.json", "", query: query_params) do
      {:ok, %_{status: 200, body: %{"actionstatus" => _}} = response} ->
        {:ok, Action.normalize(response.body)}

      {:ok, %_{body: %{"status" => "ERROR", "message" => message}}} ->
        {:error, message}

      {:ok, %_{body: %{"status" => "error", "error" => message}}} ->
        {:error, message}

      {:error, _} = error ->
        error
    end
  end

  @doc """
  Search domains registered or transferred by the reseller. The search results
  are paginated and the default number of records per page is 25. The page
  number is 0-based.

  The possible query parameters are:

  - `no-of-records`. The number of records per page.
  - `page-no`. The page number to retrieve.
  - `order-by`. The field to order the results by. The possible values are:
    - `orderid` (default)
    - `endtime` the expiry date of the product (domain mainly).
    - `timestamp` the date the product was updated.
    - `entitytypeid` the type of the product.
    - `creationtime` the date the product was created.
    - `creationdt` the date and time when the product was created.
  - `order-id`. A list of order IDs to list the details of.
  - `reseller-id`. A list of reseller IDs for retrieving products of them.
  - `customer-id`. A list of customer IDs for retrieving products of them.
  - `show-child-orders`. A boolean value to show child orders.
  - `product-key`. A list of product keys to list the details of.
  - `status`. A list of statuses to filter the results by. The possible values
    are:
    - `InActive`
    - `Active`
    - `Suspended`
    - `Pending Deleted Restorable`
    - `Deleted` - to be used for searching orders deleted in the last 30 days.
    - `Archived` - to be used for searching orders deleted more than
      30 days ago.
    - `Pending Verification` - to be used for searching orders which the
      registrant contact email address verification is pending.
    - `Failed Verification` - to be used for searching orders which has been
      deactivated due to non-verification of the registrant contact email
      address.
  - `domain-name`. The domain name to search for.
  - `privacy-enabled`. Filter the results by the privacy status of the domain.
    The possible values are:
    - `true`
    - `false`
    - `na` (not allowed)
  - `creation-data-start`. The start date to filter the results by the creation
    date.
  - `creation-data-end`. The end date to filter the results by the creation
    date.
  - `expiry-date-start`. The start date to filter the results by the expiry
    date.
  - `expiry-date-end`. The end date to filter the results by the expiry date.
  """
  def search(query_params \\ []) when is_list(query_params) do
    query_params =
      query_params
      |> Keyword.put_new(:"no-of-records", @default_no_of_records)
      |> Keyword.put_new(:"page-no", 0)

    case get("/search.json", query: query_params) do
      {:ok, response} -> response.body
      {:error, _} = error -> error
    end
  end

  @doc """
  Get the order ID for a domain. The order ID is the entity ID returned by the
  `register` function.
  """
  def get_order_id_by_domain(domain_name) do
    case get("/orderid.json", query: ["domain-name": domain_name]) do
      {:ok, %_{status: 200, body: order_id}} when is_integer(order_id) ->
        {:ok, order_id}

      {:ok, %_{body: %{"status" => "ERROR", "message" => message}}} ->
        {:error, message}

      {:error, _} = error ->
        error
    end
  end

  @doc """
  Delete a registered domain. The order_id is the entity ID returned by the
  `register` function. If you need an order_id for a domain, you can use the
  `get_order_id_by_domain` function.
  """
  def delete(domain_name) when is_binary(domain_name) do
    with {:ok, order_id} <- get_order_id_by_domain(domain_name) do
      delete(order_id)
    end
  end

  def delete(order_id) when is_integer(order_id) do
    case post("/delete.json", "", query: ["order-id": order_id]) do
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

  def cancel_transfer(domain_name) when is_binary(domain_name) do
    with {:ok, order_id} <- get_order_id_by_domain(domain_name) do
      cancel_transfer(order_id)
    end
  end

  def cancel_transfer(order_id) when is_integer(order_id) do
    case post("/cancel-transfer.json", "", query: ["order-id": order_id]) do
      {:ok, %_{status: 200, body: "Success"}} ->
        :ok

      {:ok, %_{body: %{"status" => "ERROR", "message" => message}}} ->
        {:error, message}

      {:error, _} = error ->
        error
    end
  end
end
