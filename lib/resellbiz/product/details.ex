defmodule Resellbiz.Product.Details do
  @moduledoc """
  This module is responsible for defining the information needed to build
  a request for getting the details of a product.
  """
  use TypedEctoSchema

  @primary_key false

  @typedoc """
  The product details schema is composed of the following fields:

  - `id`. The product ID.
  - `service_group`. The service group.
  - `admin_contact_group`. The admin contact group. It's giving us the type of
    the contact we need to use for the admin contact.
  - `billing_contact_group`. The billing contact group. It's giving us the type
    of the contact we need to use for the billing contact.
  - `owner_contact_group`. The owner contact group. It's giving us the type of
    the contact we need to use for the owner contact.
  - `tech_contact_group`. The tech contact group. It's giving us the type of
    the contact we need to use for the tech contact.
  - `poll_msg_support?`. A boolean indicating if the product supports poll
    messages.
  - `store_front_support?`. A boolean indicating if the product supports store
    front.
  - `bulk_allowed?`. A boolean indicating if the product allows bulk operations.
  - `lock_allowed?`. A boolean indicating if the product allows locking.
  - `parking_allowed?`. A boolean indicating if the product allows parking.
  - `privacy_protection_allowed?`. A boolean indicating if the product allows
    privacy protection.
  - `renewal_allowed?`. A boolean indicating if the product allows renewal.
  - `restore_automated?`. A boolean indicating if the product allows automated
    restoration.
  - `transfer_allowed?`. A boolean indicating if the product allows transfer.
  - `transfer_secret_required?`. A boolean indicating if the product requires a
    transfer secret.
  - `min_domain_length`. The minimum domain length.
  - `max_domain_length`. The maximum domain length.
  - `min_domain_search_length`. The minimum domain search length.
  - `max_domain_search_length`. The maximum domain search length.
  - `min_ns`. The minimum number of name servers.
  - `max_ns`. The maximum number of name servers.
  - `min_registration_year`. The minimum registration years allowed.
  - `max_registration_year`. The maximum registration years allowed.
  - `min_renewal_period`. The minimum number of days for renewal.
  - `max_renewal_period`. The maximum number of days for renewal.
  - `redeemption_graceperiod`. The redemption grace period.
  - `registry`. The registry.
  - `registry_add_graceperiod`. The registry add grace period.
  - `registry_autorenew_graceperiod`. The registry autorenew grace period.
  - `tlds`. The list of TLDs.
  """
  typed_embedded_schema do
    field(:id, :string)
    field(:service_group, :string, source: :servicegroup)
    field(:admin_contact_group, :string, source: :admincontactgroup, default: "Contact")
    field(:billing_contact_group, :string, source: :billingcontactgroup, default: "Contact")
    field(:owner_contact_group, :string, source: :registrantcontactgroup, default: "Contact")
    field(:tech_contact_group, :string, source: :techcontactgroup, default: "Contact")

    field(:poll_msg_support?, :boolean, source: :haspollmsgsupport)
    field(:store_front_support?, :boolean, source: :hasstorefrontsupport)
    field(:bulk_allowed?, :boolean, source: :isbulkallowed)
    field(:lock_allowed?, :boolean, source: :islockallowed)
    field(:parking_allowed?, :boolean, source: :isparkingallowed)
    field(:privacy_protection_allowed?, :boolean, source: :isprivacyprotectionallowed)
    field(:renewal_allowed?, :boolean, source: :isrenewallowed)
    field(:restore_automated?, :boolean, source: :isrestoreautomated)
    field(:transfer_allowed?, :boolean, source: :istransferallowed)
    field(:transfer_secret_required?, :boolean, source: :istransfersecretrequired)

    field(:min_domain_length, :integer, source: :mindomainlength)
    field(:max_domain_length, :integer, source: :maxdomainlength)

    field(:min_domain_secret_length, :integer, source: :mindomainsecretlength)
    field(:max_domain_secret_length, :integer, source: :maxdomainsecretlength)

    field(:min_ns, :integer, source: :minns)
    field(:max_ns, :integer, source: :maxns)

    field(:min_registration_year, :integer, source: :minregistrationyear)
    field(:max_registration_year, :integer, source: :maxregistrationyear)

    field(:min_renewal_period, :integer, source: :minrenewalperiod)
    field(:max_renewal_period, :integer, source: :maxrenewalperiod)

    field(:redeemption_graceperiod, :integer)
    field(:registry, :string)
    field(:registry_add_graceperiod, :integer)
    field(:registry_autorenew_graceperiod, :integer)
    field(:tlds, {:array, :string}, source: :tldlist)
  end

  @doc false
  def normalize(params) do
    Ecto.embedded_load(__MODULE__, params, :json)
  end
end
