defmodule Vyre.Channels.StatusQueue do
  use GenServer

  # 5 seconds
  @flush_interval 5_000

  def start_link(_) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  def init(_) do
    :ets.new(:status_update_throttle, [:named_table, :set, :public])
    timer = Process.send_after(self(), :flush, @flush_interval)
    {:ok, %{queue: [], timer: timer}}
  end

  def mark_as_read(user_id, channel_id, message_id) do
    key = "#{user_id}:#{channel_id}"

    # Only queue if not processed recently
    if !recently_processed?(key) do
      GenServer.cast(__MODULE__, {:mark_read, user_id, channel_id, message_id})
      mark_as_processed(key)
    end
  end

  # Add update to queue
  def handle_cast({:mark_read, user_id, channel_id, message_id}, state) do
    now = DateTime.utc_now()

    update = %{
      user_id: user_id,
      channel_id: channel_id,
      last_read_message_id: message_id,
      last_read_at: now
    }

    # Overwrite existing updates for same user/channel
    filtered_queue =
      Enum.reject(state.queue, fn item ->
        item.user_id == user_id && item.channel_id == channel_id
      end)

    {:noreply, %{state | queue: [update | filtered_queue]}}
  end

  # Flush queue to database
  def handle_info(:flush, state) do
    # Skip if empty
    new_state =
      if length(state.queue) > 0 do
        # Process in batches of 100
        state.queue
        |> Enum.chunk_every(100)
        |> Enum.each(fn batch ->
          Vyre.Repo.transaction(fn ->
            Enum.each(batch, fn update ->
              Vyre.Channels.mark_channel_as_read(
                update.user_id,
                update.channel_id,
                update.last_read_message_id
              )
            end)
          end)
        end)

        %{state | queue: []}
      else
        state
      end

    # Reset timer
    timer = Process.send_after(self(), :flush, @flush_interval)
    {:noreply, %{new_state | timer: timer}}
  end

  defp recently_processed?(key) do
    case :ets.lookup(:status_update_throttle, key) do
      [{^key, timestamp}] ->
        # Check if processed within the last 5 seconds
        DateTime.diff(DateTime.utc_now(), timestamp) < 5

      [] ->
        false
    end
  end

  defp mark_as_processed(key) do
    :ets.insert(:status_update_throttle, {key, DateTime.utc_now()})
  end
end
