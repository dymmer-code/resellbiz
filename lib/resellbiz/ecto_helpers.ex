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
