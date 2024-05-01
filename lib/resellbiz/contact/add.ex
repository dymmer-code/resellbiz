defmodule Resellbiz.Contact.Add do
  @moduledoc """
  The add module is responsible for adding a new contact to the customer's
  account. It provides functions to add a contact of different types.
  """
  use TypedEctoSchema

  import Ecto.Changeset
  import Resellbiz.EctoHelpers

  @contact_types [
    contact: "Contact",
    at_contact: "AtContact",
    br_contact: "BrContact",
    br_org_contact: "BrOrgContact",
    ca_contact: "CaContact",
    cl_contact: "ClContact",
    cn_contact: "CnContact",
    co_contact: "CoContact",
    de_contact: "DeContact",
    es_contact: "EsContact",
    eu_contact: "EuContact",
    fr_contact: "FrContact",
    mx_contact: "MxContact",
    nl_contact: "NlContact",
    nyc_contact: "NycContact",
    ru_contact: "RuContact",
    uk_contact: "UkContact",
    uk_service_contact: "UkServiceContact"
  ]

  # Required check if it's indicated for EsContact
  @es_states [
    "Albacete",
    "Alicante",
    "Almeria",
    "Araba",
    "Asturias",
    "Avila",
    "Badajoz",
    "Barcelona",
    "Bizkaia",
    "Burgos",
    "Caceres",
    "Cadiz",
    "Cantabria",
    "Castellon",
    "Ceuta",
    "Ciudad Real",
    "Cordoba",
    "Coruña, A",
    "Cuenca",
    "Gipuzkoa",
    "Girona",
    "Granada",
    "Guadalajara",
    "Huelva",
    "Huesca",
    "Illes Balears",
    "Jaen",
    "Leon",
    "Lleida",
    "Lugo",
    "Madrid",
    "Malaga",
    "Melilla",
    "Murcia",
    "Navarra",
    "Ourense",
    "Palencia",
    "Palmas, Las",
    "Pontevedra",
    "Rioja, La",
    "Salamanca",
    "Santa Cruz de Tenerife",
    "Segovia",
    "Sevilla",
    "Soria",
    "Tarragona",
    "Teruel",
    "Toledo",
    "Valencia",
    "Valladolid",
    "Zamora",
    "Zaragoza"
  ]

  @primary_key false

  @typedoc """
  The provided data for the contact. It could be in use for add and the data
  is as follows:

  - `customer_id` is the customer where we are going to create the contact.
  - `name` contact name max 255 in exception of .EU it's 50. In addition,
    an `AtContact` requires two words.
  - `company` is the name of the company, it's max 255, or 100 for .EU,
    in addition, for .EU contacts the individuals should indicate _NA_
    for this parameter. For `RuContact` or `AtContact` the company should
    be 2 words, and if that's for individuals you have to use _N A_
    (separated) or _Not Applicable_. For `EsContact` this data is optional.
  - `type` is the kind of contact, it could be whatever of the values defined
    for the data.
  - `email` the email address of the contact.
  - `telno_cc` the phone country code between 1-3 digits.
  - `telno` phone number between 4-12 digits (general) or between 3-13 (.EU).
  - `fax_cc` the fax country code between 1-3 digits.
  - `fax` phone number between 4-12 digits (general) or between 3-13 (.EU).
  - `address` the main address line, max 64 characters. The `NycContact`
    requires a valid New York city address.
  - `address_extra1` the second line of address if needed.
  - `address_extra2` the third line of address if needed.
  - `city` the name of the city, max. 64.
  - `state` max 64 characters is optional, but _EsContact_ is required to
    indicate a valid one.
  - `country` the country code as per ISO-3166-1 alpha-2.
  - `zip` the zipcode max 10 characters (general) or 16 characters (.EU)
  """
  typed_embedded_schema do
    field(:customer_id, :integer, source: :"customer-id")
    field(:name, :string)
    field(:company, :string)
    field(:type, Ecto.Enum, values: @contact_types, default: :contact, embed_as: :dumped)
    field(:email, :string)
    field(:telno_cc, :integer, source: :"phone-cc")
    field(:telno, :string, source: :phone)
    field(:fax_cc, :integer, source: :"fax-cc")
    field(:fax, :string, source: :fax)
    field(:address, :string, source: :"address-line-1")
    field(:address_extra1, :string, source: :"address-line-2")
    field(:address_extra2, :string, source: :"address-line-3")
    field(:city, :string)
    field(:state, :string)
    field(:country, :string)
    field(:zip, :string, source: :zipcode)
  end

  @required_fields ~w[name customer_id email telno_cc telno address city country zip]a
  @optional_fields ~w[type company address_extra1 address_extra2 state fax_cc fax]a

  @doc false
  def changeset(model \\ %__MODULE__{}, params) do
    params = Map.put(params, :customer_id, Application.get_env(:resellbiz, :customer_id))

    model
    |> cast(params, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
    |> validate_if_type(
      [:es_contact],
      fn changeset ->
        changeset
        |> validate_required([:state])
        |> validate_inclusion(:state, @es_states)
      end,
      fn changeset ->
        if get_change(changeset, :company) do
          changeset
        else
          put_change(changeset, :company, "Not Applicable")
        end
      end
    )
    |> validate_if_type(
      [:eu_contact],
      fn changeset ->
        changeset
        |> validate_length(:name, max: 50)
        |> validate_length(:company, max: 100)
      end,
      fn changeset ->
        changeset
        |> validate_length(:name, max: 255)
        |> validate_length(:company, max: 255)
      end
    )
    |> validate_if_type([:ru_contact, :at_contact], fn changeset ->
      if count_words(get_field(changeset, :company)) >= 2 do
        changeset
      else
        add_error(changeset, :company, "Should be at least 2 words")
      end
    end)
    |> validate_if_type([:at_contact], fn changeset ->
      if count_words(get_field(changeset, :name)) >= 2 do
        changeset
      else
        add_error(changeset, :name, "Should be at least 2 words")
      end
    end)
    |> validate_format(:telno, ~r/^[0-9]+$/, message: "Should contain only digits")
    |> validate_if_type(
      [:eu_contact],
      fn changeset ->
        validate_length(changeset, :telno, min: 3, max: 13)
      end,
      fn changeset ->
        validate_length(changeset, :telno, min: 4, max: 12)
      end
    )
    |> validate_format(:fax, ~r/^[0-9]+$/, message: "Should contain only digits")
    |> validate_if_type(
      [:eu_contact],
      fn changeset ->
        validate_length(changeset, :fax, min: 3, max: 13)
      end,
      fn changeset ->
        validate_length(changeset, :fax, min: 4, max: 12)
      end
    )
    |> validate_length(:address, max: 64)
    |> validate_length(:address_extra1, max: 64)
    |> validate_length(:address_extra2, max: 64)
    |> validate_length(:city, max: 64)
    |> validate_length(:state, max: 64)
    |> validate_format(:country, ~r/^[A-Z]{2}$/, message: "Should be ISO-3166-1 alpha-2")
    |> validate_if_type(
      [:eu_contact],
      fn changeset ->
        validate_length(changeset, :zip, max: 16)
      end,
      fn changeset ->
        validate_length(changeset, :zip, max: 10)
      end
    )
  end

  @doc """
  Converts the changeset to a list of parameters.
  """
  def to_params(changeset, data \\ nil)

  def to_params(%Ecto.Changeset{valid?: true} = changeset, nil) do
    data =
      changeset
      |> apply_changes()
      |> Ecto.embedded_dump(:url)

    module = Module.concat(__MODULE__, data.type)
    Code.ensure_loaded?(module)

    if function_exported?(module, :changeset, 1) do
      module.changeset(changeset.params)
      |> to_params(data)
    else
      {:ok, Enum.to_list(data)}
    end
  end

  def to_params(%Ecto.Changeset{valid?: true} = changeset, data) do
    extra_data =
      changeset
      |> apply_changes()
      |> Ecto.embedded_dump(:url)

    {:ok, Map.merge(data, to_attributes(extra_data)) |> Enum.to_list()}
  end

  def to_params(%Ecto.Changeset{} = changeset, _data) do
    {:error, traverse_errors(changeset)}
  end

  defp count_words(nil), do: 0

  defp count_words(string) when is_binary(string) do
    string
    |> String.split(~r/\s+/)
    |> Enum.count()
  end

  defp validate_if_type(changeset, types, then_block, else_block \\ nil) do
    changeset
    |> get_field(:type)
    |> then(&(&1 in types))
    |> if do
      then_block.(changeset)
    else
      if(else_block, do: else_block.(changeset), else: changeset)
    end
  end

  defp to_attributes(data) do
    data
    |> Enum.with_index(1)
    |> Enum.flat_map(fn {{name, value}, idx} ->
      [
        {:"attr-name#{idx}", to_string(name)},
        {:"attr-value#{idx}", value}
      ]
    end)
    |> Map.new()
  end
end
