defmodule Resellbiz.Case do
  @moduledoc """
  Simulate the Resellbiz system for replying to the requests.
  """

  def resellbiz_setup(_args) do
    bypass = Bypass.open()
    Application.put_env(:resellbiz, :url, endpoint_url(bypass))
    {:ok, bypass: bypass}
  end

  defmacro __using__(_args) do
    quote do
      use ExUnit.Case
      import Resellbiz.Case

      setup :resellbiz_setup
    end
  end

  defp endpoint_url(bypass) do
    "http://localhost:#{bypass.port()}"
  end

  def response(conn, code, data \\ []) do
    conn
    |> Plug.Conn.put_resp_content_type("application/json")
    |> Plug.Conn.resp(code, Jason.encode!(data))
  end
end
