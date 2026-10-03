defmodule Resellbiz.DomainParamsTest do
  use ExUnit.Case, async: true

  alias Resellbiz.Domain.{Register, Renew, Transfer}
  alias Resellbiz.Product.Details

  @details %Details{
    min_registration_year: 1,
    max_registration_year: 10,
    min_domain_length: 1,
    max_domain_length: 63,
    min_ns: 1,
    max_ns: 13,
    tlds: ["com"]
  }

  @contacts %{
    customer_id: 1,
    owner_contact_id: 2,
    admin_contact_id: 3,
    tech_contact_id: 4,
    billing_contact_id: 5
  }

  describe "purchase-privacy" do
    test "register sends it with the name the API expects" do
      params =
        Map.merge(@contacts, %{
          name: "domain.com",
          years: 1,
          ns: ["ns1.example.com"],
          purchase_privacy?: true
        })

      assert {:ok, query} = Register.changeset(params, @details)
      assert {:"purchase-privacy", true} in query
      refute Keyword.has_key?(query, :"purcharse-privacy")
    end

    test "transfer sends it with the name the API expects" do
      params =
        Map.merge(@contacts, %{
          name: "domain.com",
          authcode: "x",
          ns: ["ns1.example.com"],
          purchase_privacy?: true
        })

      assert {:ok, query} = Transfer.changeset(params, @details)
      assert {:"purchase-privacy", true} in query
    end

    test "renew sends it with the name the API expects" do
      params = %{
        order_id: 1,
        years: 1,
        expiration_datetime: 1_790_000_000,
        purchase_privacy?: true
      }

      assert {:ok, query} = Renew.changeset(params, @details)
      assert {:"purchase-privacy", true} in query
    end
  end
end
