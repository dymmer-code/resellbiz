defmodule Resellbiz.Product.Prices do
  @moduledoc """
  The product prices module is responsible for normalizing the product prices
  from the Resellbiz API.
  """
  use TypedEctoSchema

  @primary_key false

  @typedoc """
  The fields that are available in the product prices are the following:

  - `id`: The product ID.
  - `new_domain`: The price for adding a new domain.
  - `transfer_domain`: The price for transferring a domain.
  - `renew_domain`: The price for renewing a domain.
  - `restore_domain`: The price for restoring a domain.
  """
  typed_embedded_schema do
    field(:id, :string, primary_key: true)
    field(:new_domain, :decimal, source: :addnewdomain)
    field(:transfer_domain, :decimal, source: :addtransferdomain)
    field(:renew_domain, :decimal, source: :renewdomain)
    field(:restore_domain, :decimal, source: :restoredomain)
  end

  @doc false
  def normalize(params) do
    Ecto.embedded_load(__MODULE__, params, :json)
  end
end
