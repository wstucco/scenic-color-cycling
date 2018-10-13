defmodule Timer do
  use GenServer

  def start(pid, fps \\ 60) do
    GenServer.start_link(__MODULE__, [pid, fps])
  end

  def init([pid, fps]) do
    state = %{
      fps: fps,
      frame_time: 1_000_000 / fps,
      last_msg_time: Time.utc_now(),
      diff: 0,
      pid: pid
    }

    send(self(), :wait_for_tick)
    {:ok, state}
  end

  def set_fps(pid, fps) do
    GenServer.cast(pid, {:set_fps, fps})
  end

  def get_fps(pid) do
    GenServer.call(pid, :get_fps)
  end

  def handle_cast({:set_fps, fps}, state) do
    {:noreply, %{state | frame_time: 1_000_000 / fps, fps: fps}}
  end

  def handle_call(:get_fps, _from, state) do
    {:reply, state.fps, state}
  end

  # def handle_info(:tick, %{diff: diff, frame_time: frame_time} = state) when diff >= frame_time do
  #   IO.inspect({diff, Float.round(1_000_000 / diff, 2), frame_time})
  #   last_msg_time = Time.utc_now()
  #   send(self(), :tick)

  #   {:noreply, %{state | diff: 0, last_msg_time: last_msg_time}}
  # end

  # def handle_info(:tick, %{last_msg_time: last} = state) do
  #   diff = Time.diff(Time.utc_now(), last, :microsecond)
  #   send(self(), :tick)
  #   {:noreply, %{state | diff: diff}}
  # end

  def handle_info(:tick, %{diff: diff, frame_time: frame_time} = state) when diff >= frame_time do
    # IO.inspect({:tick, diff, Float.round(1_000_000 / diff, 2), frame_time, diff - frame_time})
    last_msg_time = Time.utc_now()
    send(state.pid, :animation_frame)
    send(self(), :wait_for_tick)

    {:noreply, %{state | diff: 0, last_msg_time: last_msg_time}}
  end

  def handle_info(:tick, state) do
    send(self(), :wait_for_tick)
    {:noreply, state}
  end

  def handle_info(:wait_for_tick, %{last_msg_time: last_tick, frame_time: frame_time} = state) do
    next_tick = Time.add(last_tick, trunc(frame_time), :microsecond)
    diff = Time.diff(next_tick, last_tick, :microsecond)
    sleep_time = div(diff - 1_000, 1_000)
    # IO.inspect({diff, sleep_time})
    # IO.inspect({:wait_for_tick, diff, sleep_time})
    Process.sleep(sleep_time)

    [last_tick]
    |> Stream.cycle()
    |> Enum.take_while(fn t ->
      Time.diff(Time.utc_now(), t, :microsecond) < frame_time
    end)

    diff = Time.diff(Time.utc_now(), last_tick, :microsecond)
    send(self(), :tick)
    {:noreply, %{state | diff: diff}}
  end
end
