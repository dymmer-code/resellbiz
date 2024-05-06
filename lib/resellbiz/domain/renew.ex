defmodule Resellbiz.Domain.Renew do
  @moduledoc """
  Renew an existent domain.
  """
  use TypedEctoSchema
  import Ecto.Changeset
  import Resellbiz.EctoHelpers
  alias Resellbiz.EctoHelpers.Timestamp
  alias Resellbiz.Product.Details

  @invoice_options [
    no_invoice: "NoInvoice",
    pay_invoice: "PayInvoice",
    keep_invoice: "KeepInvoice",
    only_add: "OnlyAdd"
  ]

  @primary_key false

  typed_embedded_schema do
    field(:order_id, :integer, source: :"order-id")
    field(:years, :integer)
    field(:expiration_datetime, Timestamp, source: :"exp-date")

    field(:invoice_option, Ecto.Enum,
      values: @invoice_options,
      default: :no_invoice,
      source: :"invoice-option",
      embed_as: :dumped
    )

    field(:purchase_privacy?, :boolean, default: false, source: :"purcharse-privacy")
    field(:auto_renew?, :boolean, default: false, source: :"auto-renew")
  end

  @required_fields ~w[order_id years expiration_datetime]a
  @optional_fields ~w[invoice_option purchase_privacy? auto_renew?]a

  @doc false
  def changeset(model \\ %__MODULE__{}, params, %Details{} = tld_details) do
    model
    |> cast(params, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
    |> validate_number(:years,
      greater_than_or_equal_to: tld_details.min_registration_year,
      less_than_or_equal_to: tld_details.max_registration_year
    )
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
