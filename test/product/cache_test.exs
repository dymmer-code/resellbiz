defmodule Resellbiz.Product.CacheTest do
  use ExUnit.Case, async: false

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
end
