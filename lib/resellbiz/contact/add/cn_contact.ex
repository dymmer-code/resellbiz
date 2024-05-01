defmodule Resellbiz.Contact.Add.CnContact do
  @moduledoc """
  This module is a specific implementation of the contact information
  for the .cn domain. It provides functions to add and get details of a
  contact.
  """
  use TypedEctoSchema
  import Ecto.Changeset

  @primary_key false

  typed_embedded_schema do
    field(:organisation_verification_id, :string)
  end

  @fields ~w[organisation_verification_id]a

  @doc false
  def changeset(model \\ %__MODULE__{}, params) do
    model
    |> cast(params, @fields)
    |> validate_required(@fields)
  end
end
