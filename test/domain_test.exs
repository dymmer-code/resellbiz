defmodule Resellbiz.DomainTest do
  use Resellbiz.Case

  describe "restore" do
    test "correctly" do
      order_id = 84_698_661

      stub(fn conn ->
        case {conn.method, conn.request_path} do
          {"GET", "/api/domains/orderid.json"} ->
            assert conn.params["domain-name"] == "domain.com"
            response(conn, 200, order_id)

          {"POST", "/api/domains/restore.json"} ->
            assert conn.query_params == %{
                     "auth-userid" => "12345678",
                     "api-key" => "abcdefg",
                     "order-id" => to_string(order_id),
                     "invoice-option" => "NoInvoice"
                   }

            response(conn, 200, %{
              "description" => "domain.com",
              "entityid" => 12_121_212,
              "eaqid" => 1_111_111,
              "actiontypedesc" => "restore",
              "actionstatus" => "Success",
              "actionstatusdesc" => "restored successfully",
              "invoiceid" => "87654",
              "sellingcurrencysymbol" => "USD",
              "sellingamount" => "5.00",
              "customerid" => "7123"
            })
        end
      end)

      # XXX: based on https://cp.us2.net/kb/answer/760
      assert {:ok,
              %Resellbiz.Domain.Action{
                action_status: :success,
                action_status_description: "restored successfully",
                action_type: nil,
                action_type_description: "restore",
                customer_id: "7123",
                description: "domain.com",
                eaqid: 1_111_111,
                entity_id: 12_121_212,
                error: nil,
                invoice_id: "87654",
                selling_currency: "USD",
                selling_price: "5.00",
                status: nil
              }} == Resellbiz.Domain.restore("domain.com")
    end
  end

  describe "set_privacy" do
    test "enables privacy protection correctly" do
      order_id = 84_698_661

      stub(fn conn ->
        case {conn.method, conn.request_path} do
          {"GET", "/api/domains/orderid.json"} ->
            assert conn.params["domain-name"] == "domain.com"
            response(conn, 200, order_id)

          {"POST", "/api/domains/modify-privacy-protection.json"} ->
            assert conn.query_params == %{
                     "auth-userid" => "12345678",
                     "api-key" => "abcdefg",
                     "order-id" => to_string(order_id),
                     "protect-privacy" => "true",
                     "reason" => "Domain owner request"
                   }

            # XXX: based on https://cp.us2.net/kb/answer/778
            response(conn, 200, %{
              "description" => "domain.com",
              "entityid" => 12_121_212,
              "eaqid" => 1_111_111,
              "actiontypedesc" => "modify-privacy-protection",
              "actionstatus" => "Success",
              "actionstatusdesc" => "Privacy Protection enabled successfully",
              "invoiceid" => "87654",
              "sellingcurrencysymbol" => "USD",
              "sellingamount" => "0.00",
              "customerid" => "7123"
            })
        end
      end)

      assert {:ok,
              %Resellbiz.Domain.Action{
                action_status: :success,
                action_status_description: "Privacy Protection enabled successfully",
                action_type: nil,
                action_type_description: "modify-privacy-protection",
                customer_id: "7123",
                description: "domain.com",
                eaqid: 1_111_111,
                entity_id: 12_121_212,
                error: nil,
                invoice_id: "87654",
                selling_currency: "USD",
                selling_price: "0.00",
                status: nil
              }} == Resellbiz.Domain.set_privacy("domain.com", true)
    end

    test "disables privacy protection correctly" do
      order_id = 84_698_661

      stub(fn conn ->
        case {conn.method, conn.request_path} do
          {"GET", "/api/domains/orderid.json"} ->
            response(conn, 200, order_id)

          {"POST", "/api/domains/modify-privacy-protection.json"} ->
            assert conn.query_params["protect-privacy"] == "false"
            assert conn.query_params["reason"] == "no longer needed"

            response(conn, 200, %{
              "description" => "domain.com",
              "entityid" => 12_121_212,
              "eaqid" => 1_111_112,
              "actiontypedesc" => "modify-privacy-protection",
              "actionstatus" => "Success",
              "actionstatusdesc" => "Privacy Protection disabled successfully"
            })
        end
      end)

      assert {:ok, %Resellbiz.Domain.Action{action_status: :success}} =
               Resellbiz.Domain.set_privacy("domain.com", false, "no longer needed")
    end

    test "returns the error message when the provider rejects the request" do
      order_id = 84_698_661

      stub(fn conn ->
        case {conn.method, conn.request_path} do
          {"GET", "/api/domains/orderid.json"} ->
            response(conn, 200, order_id)

          {"POST", "/api/domains/modify-privacy-protection.json"} ->
            response(conn, 200, %{
              "status" => "ERROR",
              "message" => "Privacy Protection not supported for this TLD"
            })
        end
      end)

      assert Resellbiz.Domain.set_privacy("domain.com", true) ==
               {:error, "Privacy Protection not supported for this TLD"}
    end
  end
end
