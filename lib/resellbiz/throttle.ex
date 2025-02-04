defmodule Resellbiz.Throttle do
  @moduledoc """
  The throttle middleware is responsible for checking the rate limit of the
  Resellbiz API. If the rate limit is exceeded, the middleware will wait for a
  certain amount of time before trying again.
  """
  @behaviour Tesla.Middleware
  require Logger

  @throttle_tries Application.compile_env(:resellbiz, :tries, 3)
  @throttle_time_to_wait Application.compile_env(
                           :resellbiz,
                           :throttle_time_to_wait,
                           :timer.seconds(1)
                         )
  @times Application.compile_env(:resellbiz, :throttle_times_per_minute, 5)

  defp check_throttle(tries \\ @throttle_tries)

  defp check_throttle(0) do
    Logger.error("Resellbiz overloaded!")
    {:error, :overloaded}
  end

  defp check_throttle(tries) do
    case Hammer.check_rate("resellbiz:global", :timer.minutes(1), @times) do
      {:allow, _count} ->
        :ok

      {:deny, _limit} ->
        Process.sleep(@throttle_time_to_wait)
        check_throttle(tries - 1)
    end
  end

  @impl Tesla.Middleware
  @doc false
  def call(env, next, _options) do
    case check_throttle() do
      :ok -> Tesla.run(env, next)
      {:error, :overloaded} -> {:error, :overloaded}
    end
  end
end
