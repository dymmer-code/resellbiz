defmodule Resellbiz.Contact.Search do
  @moduledoc """
  This module is responsible for defining the information needed to build
  a request for searching for contacts.
  """
  use TypedEctoSchema
  alias Resellbiz.Contact.Details

  @primary_key false

  typed_embedded_schema do
    field(:total, :integer, source: :recsindb)
    field(:page_size, :integer, source: :recsonpage)
    embeds_many(:result, Details)
  end

  @doc false
  def normalize(params) do
    Ecto.embedded_load(__MODULE__, params, :json)
  end
end
