defmodule Resellbiz.Throttle do
  @moduledoc """
  A Req request step responsible for checking the rate limit of the
  Resellbiz API. If the rate limit is exceeded, it waits for a certain
  amount of time before trying again.
  """
  require Logger

  use Hammer, backend: Hammer.Atomic

  @times Application.compile_env(:resellbiz, :throttle_times_per_minute, 5)
  @window :timer.minutes(1)
  # A call that has to wait for the next window can take up to a minute.
  @max_wait Application.compile_env(:resellbiz, :throttle_max_wait, :timer.seconds(65))

  defp check_throttle do
    case acquire("resellbiz:global", @times, @window, @max_wait) do
      :ok ->
        :ok

      {:error, :overloaded} = error ->
        Logger.error("Resellbiz overloaded!")
        error
    end
  end

  @doc """
  Takes one slot of `limit` per `window` milliseconds for `key`. When the
  window is full it waits for it to free (the time `Hammer` reports) instead
  of retrying a few times within seconds, which could never succeed while the
  window lasts. Gives up with `{:error, :overloaded}` only if the wait would
  go over `max_wait` milliseconds.
  """
  def acquire(key, limit, window, max_wait, waited \\ 0) do
    case hit(key, window, limit) do
      {:allow, _count} ->
        :ok

      {:deny, retry_in} when waited + retry_in <= max_wait ->
        Process.sleep(retry_in)
        acquire(key, limit, window, max_wait, waited + retry_in)

      {:deny, _retry_in} ->
        {:error, :overloaded}
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
