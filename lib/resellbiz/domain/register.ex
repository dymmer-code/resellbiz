defmodule Resellbiz.Domain.Register do
  @moduledoc """
  Register a domain with the given details. These data are used for completing
  the registration of a domain name. The domain name is registered if the
  details are valid.
  """
  use TypedEctoSchema
  import Ecto.Changeset
  import Resellbiz.EctoHelpers
  alias Resellbiz.Product.Details

  @invoice_options [
    no_invoice: "NoInvoice",
    pay_invoice: "PayInvoice",
    keep_invoice: "KeepInvoice",
    only_add: "OnlyAdd"
  ]

  @primary_key false

  typed_embedded_schema do
    field(:name, :string, source: :"domain-name")
    field(:years, :integer)
    field(:ns, {:array, :string})
    field(:customer_id, :integer, source: :"customer-id")
    field(:owner_contact_id, :integer, source: :"reg-contact-id")
    field(:admin_contact_id, :integer, source: :"admin-contact-id")
    field(:tech_contact_id, :integer, source: :"tech-contact-id")
    field(:billing_contact_id, :integer, source: :"billing-contact-id")

    field(:invoice_option, Ecto.Enum,
      values: @invoice_options,
      default: :no_invoice,
      source: :"invoice-option",
      embed_as: :dumped
    )

    field(:purchase_privacy?, :boolean, default: false, source: :"purcharse-privacy")
    field(:protect_privacy?, :boolean, default: true, source: :"protect-privacy")
    field(:auto_renew?, :boolean, default: false, source: :"auto-renew")
  end

  @required_fields ~w[
    name
    years
    ns
    customer_id
    owner_contact_id
    admin_contact_id
    tech_contact_id
    billing_contact_id
  ]a

  @optional_fields ~w[invoice_option purchase_privacy? protect_privacy? auto_renew?]a

  @doc false
  def changeset(model \\ %__MODULE__{}, params, %Details{} = tld_details) do
    model
    |> cast(params, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
    |> validate_length(:name,
      min: tld_details.min_domain_length,
      max: tld_details.max_domain_length
    )
    |> validate_number(:years,
      greater_than_or_equal_to: tld_details.min_registration_year,
      less_than_or_equal_to: tld_details.max_registration_year
    )
    |> validate_length(:ns, min: tld_details.min_ns, max: tld_details.max_ns)
    |> validate_tld(tld_details.tlds)
    |> case do
      %Ecto.Changeset{valid?: true} = changeset ->
        {:ok,
         apply_changes(changeset)
         |> Ecto.embedded_dump(:url)
         |> Map.to_list()
         |> expand_ns()}

      %Ecto.Changeset{valid?: false} = changeset ->
        {:error, traverse_errors(changeset)}
    end
  end

  defp expand_ns(query_params) do
    {ns, query_params} = Keyword.pop!(query_params, :ns)
    query_params ++ for(ns_el <- ns, do: {:ns, ns_el})
  end

  defp validate_tld(changeset, tlds) do
    with name when name != nil <- get_field(changeset, :name),
         [_base_domain, tld] <- String.split(name, ".", parts: 2),
         true <- tld in tlds do
      changeset
    else
      _ -> add_error(changeset, :name, "is using an invalid TLD")
    end
  end
end
