defmodule Resellbiz.Product.Cache do
  @moduledoc """
  The product cache module is responsible for caching the product details and
  prices from the Resellbiz API.
  """
  use GenServer
  require Logger

  @default_refresh_interval 3_600_000 * 24

  @wait_before_retry 5_000

  def start_link([]) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def get_details_by_tld(tld) do
    GenServer.call(__MODULE__, {:get_details_by_tld, tld})
  end

  def get_prices_by_tld(tld) do
    GenServer.call(__MODULE__, {:get_prices_by_tld, tld})
  end

  @impl GenServer
  def init([]) do
    if Application.get_env(:resellbiz, :auto_refresh, true) do
      {:ok, %{timestamp: NaiveDateTime.utc_now()}, {:continue, :refresh}}
    else
      {:ok, %{}}
    end
  end

  @impl GenServer
  def handle_continue(:refresh, state) do
    Logger.info("populating cache with details")

    with [_ | _] = details <- Resellbiz.Product.list_product_details(),
         Logger.info("populating cache with prices"),
         [_ | _] = prices <- Resellbiz.Product.list_product_reseller_cost_prices() do
      Logger.info("cache ready")
      timeout = Application.get_env(:resellbiz, :refresh_interval_ms, @default_refresh_interval)

      state
      |> Map.put(:details, details)
      |> Map.put(:prices, prices)
      |> Map.put(:timestamp, NaiveDateTime.utc_now())
      |> refresh(timeout)
    else
      {:error, reason} when is_map_key(state, :timestamp) ->
        Logger.error("using (#{state.timestamp}) - cannot populate the cache: #{inspect(reason)}")
        refresh(state, @wait_before_retry)

      {:error, reason} ->
        Logger.error("info not available - cannot populate the cache: #{inspect(reason)}")
        refresh(state, @wait_before_retry)
    end
  end

  defp refresh(%{timer_ref: timer_ref} = state, timeout) do
    Process.cancel_timer(timer_ref)
    refresh(Map.delete(state, :timer_ref), timeout)
  end

  defp refresh(state, timeout) do
    timer_ref = Process.send_after(self(), :refresh, timeout)
    {:noreply, Map.put(state, :timer_ref, timer_ref)}
  end

  @impl GenServer
  def handle_info(:refresh, state) do
    {:noreply, state, {:continue, :refresh}}
  end

  @impl GenServer
  def handle_call({:get_details_by_tld, tld}, _from, state) do
    if details = Enum.find(state.details, &(tld in &1.tlds)) do
      {:reply, {:ok, details}, state}
    else
      {:reply, {:error, :notfound}, state}
    end
  end

  @impl GenServer
  def handle_call({:get_prices_by_tld, tld}, _from, state) do
    with %_{id: details_id} <- Enum.find(state.details, &(tld in &1.tlds)),
         %_{} = prices <- Enum.find(state.prices, &(&1.id == details_id)) do
      {:reply, {:ok, prices}, state}
    else
      _ -> {:reply, {:error, :notfound}, state}
    end
  end
end
