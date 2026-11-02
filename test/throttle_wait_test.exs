defmodule Resellbiz.ThrottleWaitTest do
  use ExUnit.Case, async: true

  alias Resellbiz.Throttle

  test "a request over the limit waits for the window to free instead of failing" do
    key = "test:#{System.unique_integer([:positive])}"

    assert :ok = Throttle.acquire(key, 1, 300, 2_000)

    # Over the limit inside the same window: it must wait and then pass
    # (windows are aligned to the clock, so how long it waits varies).
    assert :ok = Throttle.acquire(key, 1, 300, 2_000)
  end

  test "it gives up only when the wait would exceed the maximum" do
    key = "test:#{System.unique_integer([:positive])}"

    assert :ok = Throttle.acquire(key, 1, 5_000, 100)
    assert {:error, :overloaded} = Throttle.acquire(key, 1, 5_000, 100)
  end
end
