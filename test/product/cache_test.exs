defmodule Resellbiz.Product.CacheTest do
  use Resellbiz.Case, async: false

  alias Resellbiz.Product.Cache

  describe "an unpopulated cache (auto_refresh: false, before any fetch)" do
    test "get_details_by_tld/1 returns :notfound instead of crashing" do
      assert Cache.get_details_by_tld("com") == {:error, :notfound}
    end

    test "get_prices_by_tld/1 returns :notfound instead of crashing" do
      assert Cache.get_prices_by_tld("com") == {:error, :notfound}
    end

    test "get_privacy_protection_cost/0 returns :notfound instead of crashing" do
      assert Cache.get_privacy_protection_cost() == {:error, :notfound}
    end
  end

  describe "a refresh in progress" do
    setup do
      # The fetch runs in a task of the cache, not in the test process.
      Req.Test.set_req_test_to_shared()
      on_exit(&restart_cache/0)
    end

    test "doesn't block the lookups while the API is answering" do
      test = self()

      stub(fn conn ->
        send(test, {:fetching, self()})

        receive do
          :answer -> :ok
        end

        case conn.request_path do
          "/api/products/details.json" ->
            response(conn, 200, %{"dotnet" => details_json()})

          "/api/products/reseller-cost-price.json" ->
            response(conn, 200, %{"dotnet" => prices_json(), "privacy_protection" => "1.65"})
        end
      end)

      send(Cache, :refresh)
      assert_receive {:fetching, fetcher}

      # Before, the cache did the fetch itself, so this call waited on the
      # API and failed with a timeout once it took longer than 5 seconds.
      assert Cache.get_prices_by_tld("net") == {:error, :notfound}

      send(fetcher, :answer)
      assert_receive {:fetching, fetcher}
      send(fetcher, :answer)
      assert_receive {:fetching, fetcher}
      send(fetcher, :answer)

      wait_until(fn -> match?({:ok, _}, Cache.get_privacy_protection_cost()) end)

      assert {:ok, %Resellbiz.Product.Prices{id: "dotnet"} = prices} =
               Cache.get_prices_by_tld("net")

      assert prices.new_domain == Decimal.new("10.5")
      assert {:ok, %Resellbiz.Product.Details{id: "dotnet"}} = Cache.get_details_by_tld("net")
    end

    test "keeps answering when the API fails" do
      stub(fn conn -> response(conn, 500, %{"status" => "ERROR"}) end)
      send(Cache, :refresh)

      assert Cache.get_prices_by_tld("net") == {:error, :notfound}
      assert Process.whereis(Cache)
    end
  end

  defp wait_until(fun, tries \\ 100) do
    cond do
      fun.() ->
        :ok

      tries == 0 ->
        flunk("the cache was never populated")

      true ->
        receive do
        after
          10 -> wait_until(fun, tries - 1)
        end
    end
  end

  defp restart_cache do
    Supervisor.terminate_child(Resellbiz.Supervisor, Cache)
    Supervisor.restart_child(Resellbiz.Supervisor, Cache)
  end

  defp prices_json do
    %{
      "addnewdomain" => %{"1" => "10.5"},
      "addtransferdomain" => %{"1" => "10.5"},
      "renewdomain" => %{"1" => "11.5"},
      "restoredomain" => %{"1" => "80"}
    }
  end

  defp details_json do
    %{
      "admincontactgroup" => "Contact",
      "billingcontactgroup" => "Contact",
      "dnssecdatasupported" => "extendeddsdata",
      "haspollmsgsupport" => "true",
      "hasstorefrontsupport" => "true",
      "isbulkallowed" => "true",
      "islockallowed" => "true",
      "isparkingallowed" => "true",
      "isprivacyprotectionallowed" => "true",
      "isrenewallowed" => "true",
      "isrestoreautomated" => "true",
      "istransferallowed" => "true",
      "istransfersecretrequired" => "true",
      "maxdomainlength" => "63",
      "maxdomainsecretlength" => "32",
      "maxns" => "13",
      "maxregistrationyear" => "10",
      "maxrenewalperiod" => "10",
      "mindomainlength" => "2",
      "mindomainsecretlength" => "8",
      "minns" => "0",
      "minregistrationyear" => "1",
      "minrenewalperiod" => "1",
      "redeemption_graceperiod" => "30",
      "registrantcontactgroup" => "Contact",
      "registry" => "Verisign",
      "registry_add_graceperiod" => "5",
      "registry_autorenew_graceperiod" => "45",
      "servicegroup" => "domcno",
      "techcontactgroup" => "Contact",
      "tldlist" => ["net"]
    }
  end
end
