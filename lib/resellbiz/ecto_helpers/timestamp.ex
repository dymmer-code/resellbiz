defmodule Resellbiz.EctoHelpers.Timestamp do
  @moduledoc """
  Handle epoch timestamps to be converted to NaiveDatetime and vice versa.
  """
  use Ecto.Type

  @type t() :: NaiveDateTime.t()

  @impl Ecto.Type
  @doc false
  def type, do: :string

  @impl Ecto.Type
  @doc """
  We ensure the embedding is done as dump for all of the formats (i.e. `:json`)
  """
  def embed_as(_format), do: :dump

  @impl Ecto.Type
  @doc """
  Load data when we want to convert the epoch to `NaiveDateTime`.
  """
  def load(datetime) when is_struct(datetime, NaiveDateTime),
    do: {:ok, datetime}

  def load(epoch) when is_binary(epoch) do
    load(String.to_integer(epoch))
  end

  def load(epoch) when is_integer(epoch) do
    case DateTime.from_unix(epoch, :second) do
      {:ok, datetime} -> {:ok, DateTime.to_naive(datetime)}
      {:error, _} -> :error
    end
  end

  @impl Ecto.Type
  @doc """
  The dump is performing the conversion of the `NaiveDateTime` format
  to the string format.
  """
  def dump(epoch) when is_integer(epoch),
    do: {:ok, to_string(epoch)}

  def dump(epoch) when is_binary(epoch), do: {:ok, epoch}

  def dump(datetime) when is_struct(datetime, NaiveDateTime) do
    datetime
    |> DateTime.from_naive!("Etc/UTC")
    |> DateTime.to_unix(:second)
    |> then(&{:ok, to_string(&1)})
  end

  @impl Ecto.Type
  @doc """
  Cast is performing the same as `load/1`.
  """
  def cast(datetime), do: load(datetime)
end
