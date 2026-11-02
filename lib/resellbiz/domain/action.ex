defmodule Resellbiz.Domain.Action do
  @moduledoc """
  The `Resellbiz.Domain.Action` module is responsible for managing the actions
  that can be performed on a domain. The actions are related to the domain
  lifecycle.
  """
  use TypedEctoSchema

  @action_statuses [
    failed: "Failed",
    success: "Success",
    pending: "Pending",
    admin_approved: "AdminApproved",
    unknown: "Unknown"
  ]

  # Codes the API answers with that mean one of the statuses above.
  @action_status_aliases %{"STATUS_RP_TRANSFER_REQUEST_SENT" => "Pending"}

  @action_types [
    add_new_domain: "AddNewDomain",
    add_transfer_domain: "AddTransferDomain",
    renew_domain: "RenewDomain",
    restore_domain: "RestoreDomain",
    modify_ns: "ModNS",
    lock: "Lock",
    unlock: "Unlock"
  ]

  @statuses [
    failed: "Failed",
    success: "Success",
    active: "Active",
    inactive: "InActive",
    pending_delete: "Pending Delete",
    suspended: "Suspended",
    archived: "Archived",
    deleted: "Deleted",
    admin_approved: "AdminApproved"
  ]

  @primary_key false

  typed_embedded_schema do
    field(:action_status, Ecto.Enum, values: @action_statuses, source: :actionstatus)
    field(:action_status_description, :string, source: :actionstatusdesc)
    field(:action_type, Ecto.Enum, values: @action_types, source: :actiontype)
    field(:action_type_description, :string, source: :actiontypedesc)
    field(:description, :string)
    field(:eaqid, :integer)
    field(:entity_id, :integer, source: :entityid)
    field(:status, Ecto.Enum, values: @statuses, source: :status)
    field(:error, :string)
    field(:invoice_id, :string, source: :invoiceid)
    field(:selling_currency, :string, source: :sellingcurrencysymbol)
    field(:selling_price, :string, source: :sellingamount)
    field(:customer_id, :string, source: :customerid)
  end

  @doc false
  def normalize(params) do
    params
    |> normalize_action_status()
    |> then(&Ecto.embedded_load(__MODULE__, &1, :json))
  end

  # The registrar has already acted when this answer arrives: a code that is
  # not in the list must not raise, or the caller loses the answer.
  defp normalize_action_status(%{"actionstatus" => status} = params) do
    known = Keyword.values(@action_statuses)

    status =
      cond do
        status in known -> status
        Map.has_key?(@action_status_aliases, status) -> Map.fetch!(@action_status_aliases, status)
        true -> "Unknown"
      end

    Map.put(params, "actionstatus", status)
  end

  defp normalize_action_status(params), do: params
end
