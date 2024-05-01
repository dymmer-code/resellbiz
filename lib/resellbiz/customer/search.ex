defmodule Resellbiz.Customer.Search do
  @moduledoc """
  This module is responsible for defining the information needed to build
  a request for searching for customers.
  """
  use TypedEctoSchema
  alias Resellbiz.Customer.Details

  @primary_key false

  @typedoc """
  This schema defines the structure of the response from the search API.
  The response contains the total number of records in the database, the
  number of records on the page, and the details of the customers.
  """
  typed_embedded_schema do
    field(:records_in_db, :integer, source: :recsindb)
    field(:records_on_page, :integer, source: :recsonpage)
    embeds_many(:result, Details)
  end

  @doc false
  def normalize(params) do
    Ecto.embedded_load(__MODULE__, params, :json)
  end
end
