defmodule Resellbiz.Domain.Check do
  @moduledoc """
  The check data structure is giving us the information about the result of
  checking a domain name. See `t/0`.
  """
  use TypedEctoSchema

  @statuses [
    available: "available",
    registered_through_us: "regthroughus",
    registered_through_others: "regthroughothers",
    unknown: "unknown"
  ]

  @primary_key false

  @typedoc """
  The check data type is composed by domain, class_key and the status.

  The class key will be useful to retrieve the price for that domain and
  the status could be whatever of the following ones:

  - `available` domain name available for registration.
  - `registered_through_us` domain name currently registered through the
    Registrar whose connections is being used to check the availability of
    the domain name.
  - `registered_through_others` domain name currently registered through other
    than the one whose connection is being used to check the availability of
    the domain name. If you wish to manage such a domain name through your
    Reseller / Registrar Account, you may pass a Domain Transfer API call.
  - `unknown` returned, if for some reason, the Registry connections are not
    available. You should ideally re-check the domain name availability after
    some time.

  Check https://cp.us2.net/kb/answer/764
  """
  typed_embedded_schema do
    field(:domain, :string)
    field(:class_key, :string, source: :classkey)
    field(:status, Ecto.Enum, values: @statuses)
  end

  @doc """
  Transform the parameters received from the check calls to the structure.
  """
  def normalize(params) do
    Ecto.embedded_load(__MODULE__, params, :json)
  end
end
