defmodule Resellbiz.DomainTest do
  use Resellbiz.Case

  describe "restore" do
    test "correctly", %{bypass: bypass} do
      order_id = 84_698_661

      Bypass.expect(bypass, "GET", "/api/domains/orderid.json", fn conn ->
        assert conn.params["domain-name"] == "domain.com"
        response(conn, 200, order_id)
      end)

      Bypass.expect(bypass, "POST", "/api/domains/restore.json", fn conn ->
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
end
