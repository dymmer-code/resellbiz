defmodule Resellbiz.Contact.Action do
  @moduledoc """
  The `Resellbiz.Contact.Action` module is responsible for managing the actions
  that can be performed on a contact.
  """
  use TypedEctoSchema

  @action_statuses [
    failed: "Failed",
    success: "Success",
    pending: "Pending",
    admin_approved: "AdminApproved"
  ]

  @action_types [
    delete_contact: "Del"
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
  end

  @doc false
  def normalize(params) do
    Ecto.embedded_load(__MODULE__, params, :json)
  end
end
