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

  def get_privacy_protection_cost do
    GenServer.call(__MODULE__, :get_privacy_protection_cost)
  end

  @impl GenServer
  def init([]) do
    state = %{details: %{}, prices: %{}}

    if Application.get_env(:resellbiz, :auto_refresh, true) do
      {:ok, Map.put(state, :timestamp, NaiveDateTime.utc_now()), {:continue, :refresh}}
    else
      {:ok, state}
    end
  end

  # The fetch runs in a task, not in this process: the API calls (with
  # their retries and the throttle) can take longer than the timeout of
  # the lookups, and while they run the lookups keep answering with the
  # data from the last refresh.
  @impl GenServer
  def handle_continue(:refresh, %{refresh_ref: _} = state), do: {:noreply, state}

  def handle_continue(:refresh, state) do
    task = Task.Supervisor.async_nolink(Resellbiz.TaskSupervisor, &fetch/0)
    {:noreply, Map.put(state, :refresh_ref, task.ref)}
  end

  defp fetch do
    Logger.info("populating cache with details")

    with [_ | _] = details <- Resellbiz.Product.list_product_details(),
         Logger.info("populating cache with prices"),
         [_ | _] = prices <- Resellbiz.Product.list_product_reseller_cost_prices(),
         {:ok, privacy_protection_cost} <- Resellbiz.Product.list_privacy_protection_cost() do
      {:ok, details, prices, privacy_protection_cost}
    else
      {:error, _} = error -> error
      other -> {:error, {:unexpected, other}}
    end
  end

  defp refreshed({:ok, details, prices, privacy_protection_cost}, state) do
    Logger.info("cache ready")
    timeout = Application.get_env(:resellbiz, :refresh_interval_ms, @default_refresh_interval)

    state
    |> Map.put(:details, details)
    |> Map.put(:prices, prices)
    |> Map.put(:privacy_protection_cost, privacy_protection_cost)
    |> Map.put(:timestamp, NaiveDateTime.utc_now())
    |> refresh(timeout)
  end

  defp refreshed({:error, reason}, state) when is_map_key(state, :timestamp) do
    Logger.error("using (#{state.timestamp}) - cannot populate the cache: #{inspect(reason)}")
    refresh(state, @wait_before_retry)
  end

  defp refreshed({:error, reason}, state) do
    Logger.error("info not available - cannot populate the cache: #{inspect(reason)}")
    refresh(state, @wait_before_retry)
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

  def handle_info({ref, result}, %{refresh_ref: ref} = state) do
    Process.demonitor(ref, [:flush])
    refreshed(result, Map.delete(state, :refresh_ref))
  end

  def handle_info({:DOWN, ref, :process, _pid, reason}, %{refresh_ref: ref} = state) do
    refreshed({:error, {:crashed, reason}}, Map.delete(state, :refresh_ref))
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

  @impl GenServer
  def handle_call(:get_privacy_protection_cost, _from, state) do
    case Map.fetch(state, :privacy_protection_cost) do
      {:ok, cost} -> {:reply, {:ok, cost}, state}
      :error -> {:reply, {:error, :notfound}, state}
    end
  end
end
