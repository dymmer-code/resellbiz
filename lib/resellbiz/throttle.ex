defmodule Resellbiz.Throttle do
  @moduledoc """
  A Req request step responsible for checking the rate limit of the
  Resellbiz API. If the rate limit is exceeded, it waits for a certain
  amount of time before trying again.
  """
  require Logger

  use Hammer, backend: Hammer.Atomic

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
    case hit("resellbiz:global", :timer.minutes(1), @times) do
      {:allow, _count} ->
        :ok

      {:deny, _limit} ->
        Process.sleep(@throttle_time_to_wait)
        check_throttle(tries - 1)
    end
  end

  @doc """
  Req request step: call/1 (no `next`/`options` -- request steps run before
  the request is dispatched, not around it like Tesla middleware) either
  returns the request unchanged, or short-circuits with
  `{request, %Resellbiz.OverloadedError{}}` when the rate limit couldn't be
  satisfied after retrying.
  """
  def call(request) do
    case check_throttle() do
      :ok -> request
      {:error, :overloaded} -> {request, %Resellbiz.OverloadedError{}}
    end
  end
end
