defmodule Resellbiz.OverloadedError do
  @moduledoc """
  Raised (as a Req request-step error) when `Resellbiz.Throttle` gives up
  after exhausting its retries against the local rate limit.
  """
  defexception message: "Resellbiz overloaded!"
end
