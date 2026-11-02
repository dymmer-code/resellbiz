defmodule Resellbiz.DomainTransferStatusTest do
  use Resellbiz.Case

  alias Resellbiz.Domain
  alias Resellbiz.Product.Details

  @order_id 84_698_661

  setup do
    details = %Details{
      id: "dotcom",
      tlds: ["com"],
      min_registration_year: 1,
      max_registration_year: 10,
      min_domain_length: 1,
      max_domain_length: 63,
      min_ns: 1,
      max_ns: 13
    }

    previous = :sys.get_state(Resellbiz.Product.Cache)
    :sys.replace_state(Resellbiz.Product.Cache, &Map.put(&1, :details, [details]))
    on_exit(fn -> :sys.replace_state(Resellbiz.Product.Cache, fn _ -> previous end) end)
    :ok
  end

  defp transfer_with_status(status) do
    stub(fn conn ->
      case {conn.method, conn.request_path} do
        {"GET", "/api/domains/orderid.json"} ->
          response(conn, 200, @order_id)

        {"POST", "/api/domains/transfer.json"} ->
          response(conn, 200, %{
            "eaqid" => 1,
            "actiontypedesc" => "Transfer",
            "actionstatus" => status,
            "actionstatusdesc" => "Transfer request sent"
          })
      end
    end)

    Domain.transfer("domain.com", "auth", ["ns1.example.com"], [2, 3, 4, 5])
  end

  test "a transfer request that was sent is pending, not an error" do
    assert {:ok, %Resellbiz.Domain.Action{action_status: :pending}} =
             transfer_with_status("STATUS_RP_TRANSFER_REQUEST_SENT")
  end

  test "a status the library does not know never raises after the registrar answered" do
    assert {:ok, %Resellbiz.Domain.Action{action_status: :unknown} = action} =
             transfer_with_status("SOMETHING_NEW")

    assert action.action_status_description == "Transfer request sent"
  end
end
