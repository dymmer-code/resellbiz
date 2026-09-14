defmodule Resellbiz.Telemetry do
  @moduledoc """
  Logs each real (non-stubbed) Resellbiz HTTP request at `:debug` level,
  replacing the per-module `Tesla.Middleware.Logger` configuration this
  library used before migrating to Req -- Req itself doesn't emit its own
  request-lifecycle telemetry, so this attaches to the underlying Finch
  pool's events instead (`Finch.Telemetry`).

  Requests made through a `Req.Test` stub in tests never reach Finch, so
  this handler is naturally silent during tests -- no test-specific
  handling needed.
  """
  require Logger

  @events [[:finch, :request, :stop], [:finch, :request, :exception]]

  @doc """
  Attaches this module's `handle_event/4` to the Finch request-lifecycle events.
  """
  def attach do
    :telemetry.attach_many(__MODULE__, @events, &__MODULE__.handle_event/4, nil)
  end

  @doc """
  Handles a `[:finch, :request, :stop | :exception]` event by logging the
  request. Ignores events from any other Finch pool.
  """
  def handle_event(
        [:finch, :request, :stop],
        measurements,
        %{name: Resellbiz.Finch} = metadata,
        _config
      ) do
    log(metadata.request, measurements.duration, status(metadata.result))
  end

  def handle_event(
        [:finch, :request, :exception],
        measurements,
        %{name: Resellbiz.Finch} = metadata,
        _config
      ) do
    log(metadata.request, measurements.duration, "ERROR")
  end

  # Other Finch pools (this app may not be the only Finch user on the node)
  # and any event this handler wasn't attached for -- ignored.
  def handle_event(_event, _measurements, _metadata, _config), do: :ok

  defp status({:ok, %Finch.Response{status: status}}), do: status

  # Req 0.7 uses Finch.stream_while/5 even for buffered requests. Finch
  # reports the reducer accumulator before Req builds its response.
  defp status({:ok, {%Req.Request{}, {status, _headers, _body, _trailers}}})
       when is_integer(status),
       do: status

  defp status({:error, _reason}), do: "ERROR"
  defp status({:error, _reason, _acc}), do: "ERROR"

  # Other streaming consumers can use arbitrary accumulators. Never inspect
  # them: requests and response bodies may contain credentials or private data.
  defp status(_result), do: "UNKNOWN"

  defp log(%Finch.Request{method: method, path: path}, duration_native, status) do
    time_ms = System.convert_time_unit(duration_native, :native, :millisecond)
    Logger.debug("#{method} #{path} ===> #{status} / time=#{time_ms}ms")
  end
end
