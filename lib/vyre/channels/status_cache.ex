defmodule Vyre.Channels.StatusCache do
  use GenServer

  def start_link(_) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  def get_status(user_id, channel_id) do
    # Try cache first, fall back to database
    case :ets.lookup(:channel_status_cache, "#{user_id}:#{channel_id}") do
      [{_, status}] ->
        {:ok, status}

      [] ->
        # Cache miss - get from DB and cache it
        status =
          Vyre.Repo.get_by(Vyre.Channels.UserChannelStatus,
            user_id: user_id,
            channel_id: channel_id
          )

        if status do
          :ets.insert(:channel_status_cache, {"#{user_id}:#{channel_id}", status})
          {:ok, status}
        else
          {:error, :not_found}
        end
    end
  end

  def update_status(user_id, channel_id, params) do
    # Update DB
    status =
      case Vyre.Repo.get_by(Vyre.Channels.UserChannelStatus,
             user_id: user_id,
             channel_id: channel_id
           ) do
        nil -> %Vyre.Channels.UserChannelStatus{user_id: user_id, channel_id: channel_id}
        existing -> existing
      end

    # Update cache
    {:ok, updated_status} =
      Vyre.Repo.insert_or_update(Vyre.Channels.UserChannelStatus.changeset(status, params))

    :ets.insert(:channel_status_cache, {"#{user_id}:#{channel_id}", updated_status})
    {:ok, updated_status}
  end

  def init(_) do
    :ets.new(:channel_status_cache, [:named_table, :set, :public])
    {:ok, %{}}
  end
end
