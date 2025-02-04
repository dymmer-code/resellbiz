defmodule Resellbiz.Domain.Info do
  @moduledoc """
  Information gathered from the domain.
  """
  use TypedEctoSchema
  alias Resellbiz.Contact.Details, as: ContactDetails
  alias Resellbiz.EctoHelpers.Timestamp

  @statuses [
    in_active: "InActive",
    active: "Active",
    suspended: "Suspended",
    pending_delete_restorable: "Pending Delete Restorable",
    deleted: "Deleted",
    archived: "Archived"
  ]

  @order_statuses [
    reseller_suspend: "resellersuspend",
    reseller_lock: "resellerlock",
    transfer_lock: "transferlock"
  ]

  @domain_statuses [
    sixty_day_lock: "sixtydaylock",
    renew_hold: "renewhold"
  ]

  @raa_statuses [
    verified: "Verified",
    pending: "Pending",
    suspended: "Suspended"
  ]

  @primary_key false

  @typedoc """
  The information retrieved from the domain is relative to the following fields:

  - Order ID (orderid)
  - Order Description (description)
  - Domain Name (domainname)
  - Current Order Status under the System (currentstatus) - value will be
    InActive, Active, Suspended, Pending Delete Restorable, Deleted or Archived
  - Lock/Hold on the domain name at the Registry (orderstatus) - value(s) will
    be resellersuspend, resellerlock and/or transferlock
  - Lock/Hold on the domain name in the System (domainstatus) - value(s) will
    be sixtydaylock and/or renewhold
  - Product Category (productcategory)
  - Product Key (productkey)
  - GDPR Protection (gdpr):
    - Status (key = enabled, value = True/False)
    - Eligibility (key = eligible, value = True/False)
  - Order Creation (at the Registry) Date (creationtime)
  - Registrant Contact Email Address Verification Status
    (raaVerificationStatus) - value will be Verified, Pending or Suspended
  - Start Time of the Registrant Contact Email Address Verification Process
    (raaVerificationStartTime) - will not be displayed if the Verification
    Status is Verified
  - Expiry Date (at the Registry) (endtime)
  - Whether Order belongs to a Customer directly under the Reseller
    (isImmediateReseller)
  - Reseller Chain by RID (parentkey)
  - Customer ID Associated with the Order (customerid)
  - Number of Name Servers associated with the Domain Name (noOfNameServers)
  - Name Servers (ns1, ns2, ns3, ns4, ...)
  - Child Name Servers (cns)
  - Domain Secret (domsecret)
  - Whether Order Suspended due to Expiry (isOrderSuspendedUponExpiry)
  - Whether Order Suspended by Parent Reseller (orderSuspendedByParent)
  - Whether Privacy Protection allowed for the Product Type
    (privacyprotectedallowed)
  - Whether Order is Privacy Protected (isprivacyprotected)
  - Privay Protection Details:
    - Privacy Protection Expiry Date (privacyprotectendtime)
    - Privacy Protect Registrant Contact Details (privacy-registrantcontact)
    - Privacy Protect Admin Contact Details (privacy-admincontact)
    - Privacy Protect Technical Contact Details (privacy-techcontact)
    - Privacy Protect Billing Contact Details (privacy-billingcontact)
  - Premium DNS Details:
    - Whether Premium DNS is allowed for the Product Type (premiumdnsallowed)
    - Status of Premium DNS (premiumdnsenabled)
    - Expiry date of the Premium DNS order (premiumdnsendtime)
    - Name Server details for Premium DNS in CSV format (premiumdnsnameservers)
  - Whether Order Deletion is Allowed (allowdeletion)
  - Registrant Contact ID (registrantcontactid)
  - Registrant Contact Details (registrantcontact)
  - Admin Contact ID (admincontactid)
  - Admin Contact Details (admincontact)
  - Technical Contact ID (techcontactid)
  - Technical Contact Details (techcontact)
  - Billing Contact ID (billingcontactid)
  - Billing Contact Details (billingcontact)
  - Auto Renewal (recurring)
  - Delegation Signer (DS) Record Details (dnssec):
    - Key Tag (keytag)
    - Algorithm (algorithm)
    - Digest Type (digesttype)
    - Digest (digest)

  Via https://cp.us2.net/kb/answer/1755
  """
  typed_embedded_schema do
    field(:id, :integer, source: :orderid, primary_key: true)
    field(:description, :string)
    field(:domain_name, :string, source: :domainname)
    field(:status, Ecto.Enum, values: @statuses, source: :currentstatus)
    field(:order_status, {:array, Ecto.Enum}, values: @order_statuses, source: :orderstatus)
    field(:domain_status, {:array, Ecto.Enum}, values: @domain_statuses, source: :domainstatus)
    field(:product_category, :string, source: :productcategory)
    field(:product_key, :string, source: :productkey)

    embeds_one :gdpr, Gdpr do
      @moduledoc """
      GDPR information to know if the domain is elegible and if that's enabled.
      """
      field(:elegible?, :boolean, source: :elegible)
      field(:enabled?, :boolean, source: :enabled)
    end

    field(:creation_time, Timestamp, source: :creationtime)

    field(:contact_verification_status, Ecto.Enum,
      values: @raa_statuses,
      source: :raaVerificationStatus
    )

    field(:contact_verification_start, Timestamp, source: :raaVerificationStartTime)
    field(:expiration_time, Timestamp, source: :endtime)
    field(:immediate_reseller?, :boolean, source: :isImmediateReseller)
    field(:parent_key, :string, source: :parentkey)
    field(:customer_id, :integer, source: :customerid)
    field(:number_of_ns, :integer, source: :noOfNameServers)
    field(:ns1, :string)
    field(:ns2, :string)
    field(:ns3, :string)
    field(:ns4, :string)
    field(:ns5, :string)
    field(:child_ns, :map, source: :cns)
    field(:domain_secret, :string, source: :domsecret)
    field(:suspended_due_to_expiry?, :boolean, source: :isOrderSuspendedUponExpiry)
    field(:suspended_by_parent_reseller?, :boolean, source: :orderSuspendedByParent)
    field(:privacy_protected_allowed?, :boolean, source: :privacyprotectedallowed)
    field(:privacy_protected?, :boolean, source: :isprivacyprotected)
    field(:allow_deletion?, :boolean, source: :allowdeletion)
    field(:owner_contact_id, :integer, source: :registrantcontactid)
    embeds_one(:owner_contact_details, ContactDetails, source: :registrantcontact)
    field(:admin_contact_id, :integer, source: :admincontactid)
    embeds_one(:admin_contact_details, ContactDetails, source: :admincontact)
    field(:tech_contact_id, :integer, source: :techcontactid)
    embeds_one(:tech_contact_details, ContactDetails, source: :techcontact)
    field(:billing_contact_id, :integer, source: :billingcontactid)
    embeds_one(:billing_contact_details, ContactDetails, source: :billingcontact)
    field(:auto_renew?, :boolean, source: :recurring)
    field(:dnssec, {:array, :string})
  end

  @doc false
  def normalize(params) do
    Ecto.embedded_load(__MODULE__, params, :json)
  end
end
