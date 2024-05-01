defmodule Resellbiz.Customer.Details do
  @moduledoc """
  The details of the customer are the data that we can retrieve from the
  customer. It includes the customer name, username, company, email,
  phone number, address, city, state, country, and zip code among other
  data.
  """
  use TypedEctoSchema

  @primary_key false

  @statuses [
    active: "Active",
    inactive: "Inactive",
    suspended: "Suspended"
  ]

  @typedoc """
  The provided data for the customer. It could be in use for search,
  get details, add, and modify and the data is as follows:

  - `id` the customer id.
  - `reseller_id` the reseller id.
  - `name` customer name.
  - `username` the username of the customer.
  - `company` is the name of the company, we indicate _NA_ for individuals.
  - `email` the email address of the customer.
  - `telno_cc` the phone country code between 1-3 digits.
  - `telno` phone number.
  - `city` the name of the city.
  - `state` (optional) the state of the customer.
  - `country` the country code as per ISO-3166-1 alpha-2.
  - `zip` the zipcode of the customer.
  - `pin` the PIN of the customer.
  - `creation_date` the creation date of the customer.
  - `status` the status of the customer.
  - `sales_contact_id` the sales contact id.
  - `language_preference` the language preference of the customer.
  - `total_receipts` the total receipts of the customer.
  - `website_count` the number of websites the customer has.
  """
  typed_embedded_schema do
    field(:id, :integer, primary_key: true, source: :customerid)
    field(:reseller_id, :integer, source: :resellerid)
    field(:name, :string)
    field(:username, :string)
    field(:company, :string)
    field(:email, :string, source: :useremail)
    field(:telno_cc, :integer, source: :telnocc)
    field(:telno, :string, source: :telno)
    field(:address, :string, source: :address1)
    field(:address_extra1, :string, source: :address2)
    field(:address_extra2, :string, source: :address3)
    field(:city, :string)
    field(:state, :string)
    field(:country, :string)
    field(:zip, :string)
    field(:pin, :string)
    field(:creation_date, :integer, source: :creationdt)
    field(:status, Ecto.Enum, values: @statuses, source: :customerstatus)
    field(:sales_contact_id, :integer, source: :salescontactid)
    field(:language_preference, :string, source: :langpref)
    field(:total_receipts, :decimal, source: :totalreceipts)
    field(:website_count, :integer, source: :websitecount)
  end

  @doc false
  def normalize(params) do
    Ecto.embedded_load(__MODULE__, params, :json)
  end
end
