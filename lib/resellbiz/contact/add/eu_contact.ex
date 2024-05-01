defmodule Resellbiz.Contact.Add.EuContact do
  @moduledoc """
  This module is responsible for the schema of the EU contact.
  """
  use TypedEctoSchema
  import Ecto.Changeset

  @countries ~w[AT BE BG CY CZ DE DK EE ES FI FR GR HR HU IE IT LT LU LV MT NL PL PT RO SE SI SK]a

  @primary_key false

  typed_embedded_schema do
    field(:country_of_citizenship, Ecto.Enum,
      values: @countries,
      source: :countryOfCitizenship,
      embed_as: :dumped
    )
  end

  @fields ~w[country_of_citizenship]a

  @doc false
  def changeset(model \\ %__MODULE__{}, params) do
    model
    |> cast(params, @fields)
    |> validate_required(@fields)
  end
end
