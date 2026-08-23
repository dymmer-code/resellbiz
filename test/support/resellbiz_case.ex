defmodule Resellbiz.Case do
  @moduledoc """
  Simulate the Resellbiz system for replying to requests, via a `Req.Test`
  stub instead of a real (Bypass-backed) HTTP server.

  Every client module (`Domain`, `Contact`, `Customer`, `Product`) builds
  its request through `Resellbiz.Client.new/1`, which merges in
  `Application.get_env(:resellbiz, :req_options, [])` -- so pointing that
  at a single shared `Req.Test` stub here is enough for all of them, the
  same way one shared `Bypass.open()` on one port used to serve every
  module's requests before this app moved off Tesla.
  """

  def resellbiz_setup(_args) do
    Application.put_env(:resellbiz, :req_options, plug: {Req.Test, __MODULE__})
    :ok
  end

  defmacro __using__(_args) do
    quote do
      use ExUnit.Case
      import Resellbiz.Case

      setup :resellbiz_setup
    end
  end

  @doc """
  Registers `stub_fun` as this test's Resellbiz stub -- call once per test
  with a function that pattern-matches on `{conn.method, conn.request_path}`
  to reply differently per endpoint, the same way a test used to make
  several `Bypass.expect/4` calls against one shared bypass server.
  """
  def stub(stub_fun) when is_function(stub_fun, 1) do
    Req.Test.stub(__MODULE__, stub_fun)
  end

  def response(conn, code, data \\ []) do
    conn
    |> Plug.Conn.put_resp_content_type("application/json")
    |> Plug.Conn.resp(code, Jason.encode!(data))
  end
end
