defmodule Resellbiz.DomainInfoUnknownValuesTest do
  use ExUnit.Case, async: true

  alias Resellbiz.Domain.Info

  test "a verification status the library does not know is left empty instead of raising" do
    info =
      Info.normalize(%{
        "domainname" => "domain.com",
        "currentstatus" => "InActive",
        "raaVerificationStatus" => "NA"
      })

    assert info.domain_name == "domain.com"
    assert info.status == :in_active
    assert info.contact_verification_status == nil
  end

  test "unknown values inside a list of statuses are dropped" do
    info =
      Info.normalize(%{
        "domainname" => "domain.com",
        "currentstatus" => "SomethingNew",
        "orderstatus" => ["transferlock", "SomethingNew"]
      })

    assert info.status == nil
    assert info.order_status == [:transfer_lock]
  end
end
