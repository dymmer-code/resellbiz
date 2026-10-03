defmodule Resellbiz.DomainPrivacyTest do
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

  defp action(conn) do
    response(conn, 200, %{
      "eaqid" => 1,
      "actiontypedesc" => "action",
      "actionstatus" => "Success",
      "actionstatusdesc" => "done"
    })
  end

  # Reports the purchase-privacy parameter each call to `path` sends.
  defp stub_action(path) do
    test_pid = self()

    stub(fn conn ->
      case {conn.method, conn.request_path} do
        {"GET", "/api/domains/orderid.json"} ->
          response(conn, 200, @order_id)

        {"POST", ^path} ->
          send(test_pid, {:privacy, Map.get(conn.query_params, "purchase-privacy")})
          action(conn)
      end
    end)
  end

  test "renew buys privacy protection only when asked" do
    stub_action("/api/domains/renew.json")
    assert {:ok, _} = Domain.renew("domain.com", 1, 1_790_000_000, purchase_privacy: true)
    assert_received {:privacy, "true"}

    assert {:ok, _} = Domain.renew("domain.com", 1, 1_790_000_000)
    assert_received {:privacy, "false"}
  end

  test "transfer buys privacy protection when asked" do
    stub_action("/api/domains/transfer.json")

    assert {:ok, _} =
             Domain.transfer("domain.com", "auth", ["ns1.example.com"], [2, 3, 4, 5],
               purchase_privacy: true
             )

    assert_received {:privacy, "true"}

    assert {:error, :invalid_contacts} =
             Domain.transfer("domain.com", "auth", ["ns1.example.com"], [2])
  end

  test "register buys privacy protection when asked" do
    stub_action("/api/domains/register.json")

    assert {:ok, _} =
             Domain.register("domain.com", 1, ["ns1.example.com"], [2, 3, 4, 5],
               purchase_privacy: true
             )

    assert_received {:privacy, "true"}

    assert {:error, :invalid_contacts} =
             Domain.register("domain.com", 1, ["ns1.example.com"], [2])
  end
end
