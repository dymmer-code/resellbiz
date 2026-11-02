defmodule Resellbiz.EctoHelpers do
  @moduledoc """
  Functions that can be imported to Ecto Schema modules to provide some useful
  functions.
  """
  import Ecto.Changeset

  @doc """
  Loads the data in a more permissive way that `Ecto.embedded_load/3`.
  """
  def load(module, params) do
    defaults = module.__schema__(:loaded)

    for {key, data} <- module.__schema__(:load), into: %{} do
      case data do
        {:source, name, _type} ->
          {key, params[to_string(name)] || Map.get(defaults, key)}

        _ ->
          {key, params[to_string(key)] || Map.get(defaults, key)}
      end
    end
  end

  @doc """
  Removes from `params` the values an `Ecto.Enum` field of `module` does not
  list, so that loading them leaves the field empty. The registrar can start
  answering with a new code at any time, and `Ecto.embedded_load/3` raises on
  it after the call already happened.
  """
  def drop_unknown_enum_values(module, params) do
    for {field, load} <- module.__schema__(:load), reduce: params do
      params ->
        key = to_string(source_name(field, load))

        case {Map.fetch(params, key), enum_values(module, field, load)} do
          {{:ok, value}, {:ok, known, :one}} ->
            if value in known, do: params, else: Map.delete(params, key)

          {{:ok, values}, {:ok, known, :many}} when is_list(values) ->
            Map.put(params, key, Enum.filter(values, &(&1 in known)))

          _ ->
            params
        end
    end
  end

  defp source_name(_field, {:source, name, _type}), do: name
  defp source_name(field, _load), do: field

  defp enum_values(module, field, {:source, _name, type}), do: enum_values(module, field, type)

  defp enum_values(module, field, {:parameterized, {Ecto.Enum, _}}) do
    {:ok, module |> Ecto.Enum.mappings(field) |> Keyword.values() |> Enum.map(&to_string/1), :one}
  end

  defp enum_values(module, field, {:array, {:parameterized, {Ecto.Enum, _}}}) do
    {:ok, module |> Ecto.Enum.mappings(field) |> Keyword.values() |> Enum.map(&to_string/1),
     :many}
  end

  defp enum_values(_module, _field, _type), do: :error

  @doc """
  Retrieve all nested errors to a plain error tuple.
  """
  def traverse_errors(changeset) do
    traverse_errors(changeset, fn {msg, opts} ->
      Regex.replace(~r"%{(\w+)}", msg, fn _, key ->
        opts |> Keyword.get(String.to_existing_atom(key), key) |> to_string()
      end)
    end)
  end
end
