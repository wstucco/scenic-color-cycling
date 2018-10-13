defmodule ColorCycling.Component.FPS do
  use ScenicME.Component

  alias Scenic.Graph
  alias ColorCycling.TimeFormatter, as: Formatter
  import Scenic.Primitives, only: [{:text, 3}]

  @opts [translate: {00, 20}, fill: :red]

  # --------------------------------------------------------
  def verify(scene) when is_atom(scene), do: {:ok, scene}
  def verify({scene, _} = data) when is_atom(scene), do: {:ok, data}
  def verify(_), do: :invalid_data

  # ----------------------------------------------------------------------------
  def init(_data, _opts, _parent) do
    graph =
      Graph.build(font: :roboto, font_size: 24)
      |> text("", id: :fps)
      |> push_graph()

    {:ok, %{graph: graph, diffs: [], counters: [0, 0, 0, 0]}}
  end

  def animation_frame(%{frame: 0}, %{graph: graph} = state) do
    s = ~s(Frame: 0\nTime: 0s\nFPS: 0)

    graph =
      graph
      |> Graph.modify(:fps, &text(&1, s, @opts))
      |> push_graph()

    {:noreply, %{state | graph: graph}}
  end

  def animation_frame(
        %{frame: frame, elapsed_time: time, diff: diff, fps: fps},
        %{diffs: diffs} = state
      )
      when frame == 0 or rem(frame, fps) == 0 do
    global_fps = frame / time * 1_000_000

    diffs = [diff | diffs] |> Enum.take(fps * 5)
    last_5_sec_diff = Enum.sum(diffs) / (fps * 5)
    last_2_sec_diff = (diffs |> Enum.take(fps * 2) |> Enum.sum()) / (fps * 2)
    last_1_sec_diff = (diffs |> Enum.take(fps) |> Enum.sum()) / fps

    last_5_sec_fps =
      1_000 /
        if last_5_sec_diff == 0 do
          1
        else
          last_5_sec_diff
        end

    last_2_sec_fps =
      1_000 /
        if last_2_sec_diff == 0 do
          1
        else
          last_2_sec_diff
        end

    last_1_sec_fps =
      1_000 /
        if last_1_sec_diff == 0 do
          1
        else
          last_1_sec_diff
        end

    global_fps =
      global_fps
      |> Number.Delimit.number_to_delimited(precision: 2)

    last_5_sec_fps =
      last_5_sec_fps
      |> Number.Delimit.number_to_delimited(precision: 2)

    last_2_sec_fps =
      last_2_sec_fps
      |> Number.Delimit.number_to_delimited(precision: 2)

    last_1_sec_fps =
      last_1_sec_fps
      |> Number.Delimit.number_to_delimited(precision: 2)

    counters = [
      global_fps,
      last_1_sec_fps,
      last_2_sec_fps,
      last_5_sec_fps
    ]

    {:noreply, %{state | diffs: diffs, counters: counters}}
  end

  def animation_frame(
        %{diff: diff, elapsed_time: time, frame: frame, fps: fps},
        %{graph: graph} = state
      ) do
    [global_fps, last_1_sec_fps, last_2_sec_fps, last_5_sec_fps] = state.counters

    frame =
      frame
      |> Number.Delimit.number_to_delimited(precision: 0)

    s = """
    Frames: #{frame}
    Time: #{Formatter.format(time)}
    Target FPS: #{fps}
    FPS 1/2/5 sec: #{last_1_sec_fps}/#{last_2_sec_fps}/#{last_5_sec_fps}
    Global FPS: #{global_fps}
    """

    graph =
      graph
      |> Graph.modify(:fps, &text(&1, s, @opts))
      |> push_graph()

    {:noreply, %{state | graph: graph, diffs: [diff | state.diffs]}}
  end
end
