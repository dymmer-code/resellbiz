defmodule Resellbiz.TelemetryTest do
  use ExUnit.Case, async: true

  import ExUnit.CaptureLog

  alias Resellbiz.Telemetry

  test "logs the HTTP status from a Finch response" do
    assert log_result({:ok, %Finch.Response{status: 201}}) =~ "===> 201"
  end

  test "logs the HTTP status from Req's streaming accumulator" do
    request = Req.new(url: "https://example.invalid/details.json")
    assert log_result({:ok, {request, {200, [], ["{}"], []}}}) =~ "===> 200"
    assert log_result({:ok, {request, {503, [], [], []}}}) =~ "===> 503"
  end

  test "logs transport errors with and without a streaming accumulator" do
    error = %Mint.TransportError{reason: :closed}
    request = Req.new(url: "https://example.invalid/details.json")
    assert log_result({:error, error}) =~ "===> ERROR"
    assert log_result({:error, error, {request, {nil, [], [], []}}}) =~ "===> ERROR"
  end

  test "tolerates other streaming accumulators without inspecting their contents" do
    log = log_result({:ok, %{secret: "private-value"}})
    assert log =~ "===> UNKNOWN"
    refute log =~ "private-value"
  end

  test "ignores requests from another Finch pool" do
    assert capture_log(fn ->
             Telemetry.handle_event([:finch, :request, :stop], %{}, %{name: Other.Finch}, nil)
           end) == ""
  end

  test "logs request exceptions" do
    assert capture_log([level: :debug], fn ->
             Telemetry.handle_event(
               [:finch, :request, :exception],
               %{duration: 1},
               %{name: Resellbiz.Finch, request: request()},
               nil
             )
           end) =~ "===> ERROR"
  end

  test "continues logging subsequent requests without detaching" do
    event = [:finch, :request, :stop]
    handler_id = {__MODULE__, make_ref()}
    :ok = :telemetry.attach(handler_id, event, &Telemetry.handle_event/4, nil)
    on_exit(fn -> :telemetry.detach(handler_id) end)
    req = Req.new(url: "https://example.invalid/details.json")

    log =
      capture_log([level: :debug], fn ->
        for status <- [200, 201] do
          :telemetry.execute(event, %{duration: 1}, %{
            name: Resellbiz.Finch,
            request: request(),
            result: {:ok, {req, {status, [], [], []}}}
          })
        end
      end)

    assert log =~ "===> 200"
    assert log =~ "===> 201"
    assert Enum.any?(:telemetry.list_handlers(event), &(&1.id == handler_id))
  end

  test "does not log query credentials" do
    log = log_result({:ok, %Finch.Response{status: 200}})
    assert log =~ "/details.json"
    refute log =~ "test-api-secret"
    refute log =~ "api-key"
  end

  defp log_result(result) do
    capture_log([level: :debug], fn ->
      Telemetry.handle_event(
        [:finch, :request, :stop],
        %{duration: 1},
        %{name: Resellbiz.Finch, request: request(), result: result},
        nil
      )
    end)
  end

  defp request do
    Finch.build(:get, "https://example.invalid/details.json?api-key=test-api-secret")
  end
end
