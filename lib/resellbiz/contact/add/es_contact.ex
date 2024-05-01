defmodule Resellbiz.Contact.Add.EsContact do
  @moduledoc """
  This module is a specific implementation of the contact module for the
  Spanish domains. It provides functions to add a contact with the Spanish
  specific fields.
  """
  use TypedEctoSchema
  import Ecto.Changeset

  @form_juridica [
    natural_person: 1,
    economic_interest_group: 39,
    association: 47,
    sports_association: 59,
    trade_association: 68,
    savings_bank: 124,
    community_property: 150,
    condominium: 152,
    religious_institution: 164,
    consulate: 181,
    public_law_association: 197,
    embassy: 203,
    municipality: 229,
    sports_federation: 269,
    foundation: 286,
    mutual_insurance_company: 365,
    provincial_government_body: 434,
    national_government_body: 436,
    political_party: 439,
    trade_union: 476,
    farm_partnership: 510,
    public_limited_company: 524,
    sports_public_limited_company: 525,
    partnership: 554,
    general_partnership: 560,
    limited_partnership: 562,
    cooperative: 566,
    worker_owned_company: 608,
    limited_liability_company: 612,
    spanish_company_branch: 713,
    temporary_consortium: 717,
    worker_owned_limited_company: 744,
    provincial_government_entity: 745,
    national_government_entity: 746,
    local_government_entity: 747,
    others: 877,
    designation_of_origin_regulatory_council: 878,
    natural_area_management_entity: 879
  ]

  @tipo_identificacion [
    dni_nif: 1,
    nie: 3,
    other: 0
  ]

  @primary_key false

  typed_embedded_schema do
    field(:es_form_juridica, Ecto.Enum, values: @form_juridica, embed_as: :dumped)
    field(:es_tipo_identificacion, Ecto.Enum, values: @tipo_identificacion, embed_as: :dumped)
    field(:es_identificacion, :string)
  end

  @fields ~w[es_form_juridica es_tipo_identificacion es_identificacion]a

  @doc false
  def changeset(model \\ %__MODULE__{}, params) do
    model
    |> cast(params, @fields)
    |> validate_required(@fields)
  end
end
