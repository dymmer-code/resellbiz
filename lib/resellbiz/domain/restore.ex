defmodule Resellbiz.Domain.Restore do
  @moduledoc """
  Restore a domain with the given details.
  """
  use TypedEctoSchema
  import Ecto.Changeset
  import Resellbiz.EctoHelpers

  @invoice_options [
    no_invoice: "NoInvoice",
    pay_invoice: "PayInvoice",
    keep_invoice: "KeepInvoice",
    only_add: "OnlyAdd"
  ]

  @primary_key false

  typed_embedded_schema do
    field(:order_id, :integer, source: :"order-id")

    field(:invoice_option, Ecto.Enum,
      values: @invoice_options,
      default: :no_invoice,
      source: :"invoice-option",
      embed_as: :dumped
    )
  end

  @required_fields ~w[order_id]a
  @optional_fields ~w[invoice_option]a

  @doc false
  def changeset(model \\ %__MODULE__{}, params) do
    model
    |> cast(params, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
    |> case do
      %Ecto.Changeset{valid?: true} = changeset ->
        {:ok,
         apply_changes(changeset)
         |> Ecto.embedded_dump(:url)
         |> Map.to_list()}

      %Ecto.Changeset{valid?: false} = changeset ->
        {:error, traverse_errors(changeset)}
    end
  end
end
