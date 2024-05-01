defmodule Resellbiz.Contact.Details do
  @moduledoc """
  The details of the contact are the data that we can retrieve from the
  contact. It includes the contact name, company, type, email, phone number,
  address, city, state, country, zip code, and status.
  """
  use TypedEctoSchema

  @contact_types [
    contact: "Contact",
    at_contact: "AtContact",
    br_contact: "BrContact",
    br_org_contact: "BrOrgContact",
    ca_contact: "CaContact",
    cl_contact: "ClContact",
    cn_contact: "CnContact",
    co_contact: "CoContact",
    de_contact: "DeContact",
    es_contact: "EsContact",
    eu_contact: "EuContact",
    fr_contact: "FrContact",
    mx_contact: "MxContact",
    nl_contact: "NlContact",
    nyc_contact: "NycContact",
    ru_contact: "RuContact",
    uk_contact: "UkContact",
    uk_service_contact: "UkServiceContact"
  ]

  @statuses [
    active: "Active"
  ]

  @primary_key false

  @typedoc """
  The provided data for the contact. It could be in use for search,
  get details, add, and modify and the data is as follows:

  - `name` contact name max 255 in exception of .EU it's 50. In addition,
    an `AtContact` requires two words.
  - `company` is the name of the company, it's max 255, or 100 for .EU,
    in addition, for .EU contacts the individuals should indicate _NA_
    for this parameter. For `RuContact` or `AtContact` the company should
    be 2 words, and if that's for individuals you have to use _N A_
    (separated) or _Not Applicable_. For `EsContact` this data is optional.
  - `type` is the kind of contact, it could be whatever of the values defined
    for the data.
  - `email` the email address of the contact.
  - `telno_cc` the phone country code between 1-3 digits.
  - `telno` phone number between 4-12 digits (general) or between 3-13 (.EU).
  - `address` the main address line, max 64 characters. The `NycContact`
    requires a valid New York city address.
  - `address_extra1` the second line of address if needed.
  - `address_extra2` the third line of address if needed.
  - `city` the name of the city, max. 64.
  - `state` max 64 characters is optional, but _EsContact_ is required to
    indicate a valid one.
  - `country` the country code as per ISO-3166-1 alpha-2.
  - `zip` the zipcode max 10 characters (general) or 16 characters (.EU)
  - `status` the status of the contact. It's useful and populated when we are
    retrieving the details or searching for contacts.
  """
  typed_embedded_schema do
    field(:id, :integer, primary_key: true, source: :contactid)
    field(:name, :string)
    field(:company, :string)
    field(:type, Ecto.Enum, values: @contact_types, default: :contact)
    field(:email, :string, source: :emailaddr)
    field(:telno_cc, :integer, source: :telnocc)
    field(:telno, :string, source: :telno)
    field(:address, :string, source: :address1)
    field(:address_extra1, :string, source: :address2)
    field(:address_extra2, :string, source: :address3)
    field(:city, :string)
    field(:state, :string)
    field(:country, :string)
    field(:zip, :string)
    field(:status, Ecto.Enum, values: @statuses, source: :currentstatus)
  end

  @doc false
  def normalize(params) do
    Ecto.embedded_load(__MODULE__, params, :json)
  end
end
