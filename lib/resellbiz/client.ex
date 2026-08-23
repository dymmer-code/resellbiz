defmodule Resellbiz.Client do
  @moduledoc """
  Builds the shared `Req.Request` used by every Resellbiz API module
  (`Domain`, `Contact`, `Customer`, `Product`) -- same base URL shape, same
  auth query params, same throttle step, same Finch pool. The only thing
  that varies per caller is the API sub-path (e.g. `/api/domains`).
  """

  @doc """
  Builds a `Req.Request` scoped to `path` (e.g. `"/api/domains"`).

  `Application.get_env(:resellbiz, :req_options, [])` is merged in last so
  tests can route requests to a `Req.Test` stub (see `Resellbiz.Case`)
  without this module needing to know anything about how it's being tested.
  """
  def new(path) do
    [
      base_url: Application.get_env(:resellbiz, :url) <> path,
      params: [
        "auth-userid": Application.get_env(:resellbiz, :reseller_id),
        "api-key": Application.get_env(:resellbiz, :api_key)
      ],
      finch: [name: Resellbiz.Finch]
    ]
    |> Keyword.merge(Application.get_env(:resellbiz, :req_options, []))
    |> Req.new()
    |> Req.Request.append_request_steps(throttle: &Resellbiz.Throttle.call/1)
  end
end
