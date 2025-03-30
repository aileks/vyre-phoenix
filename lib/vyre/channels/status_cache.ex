defmodule Vyre.Channels.StatusCache do
  use GenServer

  def start_link(_) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  @impl true
  def init(_) do
    if :ets.whereis(:channel_status_cache) == :undefined do
      :ets.new(:channel_status_cache, [:named_table, :set, :public])
    end

    {:ok, %{}}
  end

  def make_key(user_id, channel_id) do
    "#{user_id}:#{channel_id}"
  end

  def get_status(user_id, channel_id) do
    key = make_key(user_id, channel_id)

    case :ets.lookup(:channel_status_cache, key) do
      [{^key, status}] ->
        {:ok, status}

      [] ->
        # Cache miss - get from DB and cache it
        status =
          Vyre.Repo.get_by(Vyre.Channels.UserChannelStatus,
            user_id: user_id,
            channel_id: channel_id
          )

        if status do
          :ets.insert(:channel_status_cache, {key, status})
          {:ok, status}
        else
          {:error, :not_found}
        end
    end
  end

  def update_status(user_id, channel_id, params) do
    key = make_key(user_id, channel_id)

    # Create a proper struct for the cache
    cache_entry = struct(Vyre.Channels.UserChannelStatus, params)

    # Update cache
    :ets.insert(:channel_status_cache, {key, cache_entry})

    # Add updated_at timestamp for cache freshness tracking
    cache_entry = Map.put(cache_entry, :updated_at, DateTime.utc_now())

    {:ok, cache_entry}
  end

  def invalidate_status(user_id, channel_id) do
    key = make_key(user_id, channel_id)
    :ets.delete(:channel_status_cache, key)
  end
end
