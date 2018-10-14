defmodule ColorCycling.Component.FPSMultiplier do
  use ScenicME.Component

  alias Scenic.Graph
  import Scenic.Primitives, only: [{:text, 3}]
  import Scenic.Components, only: [{:slider, 3}]

  @multipliers [1 / 8, 1 / 4, 1 / 2, 3 / 4, 1, 1.25, 1.5]

  @base_fps 60

  # --------------------------------------------------------
  def verify(scene) when is_atom(scene), do: {:ok, scene}
  def verify({scene, _} = data) when is_atom(scene), do: {:ok, data}
  def verify(_), do: :invalid_data

  def init(_data, _opts, _parent) do
    graph =
      Graph.build(font: :roboto, font_size: 24)
      |> text("FPS mulitplier: 1 / FPS: #{@base_fps}", id: :fps_multiplier_text, t: {0, 10})
      |> slider({@multipliers, 1}, id: :fps_multiplier_slider, t: {0, 20})
      |> push_graph()

    {:ok, %{graph: graph, fps: @base_fps}}
  end

  def filter_event({:value_changed, :fps_multiplier_slider, multiplier}, _pid, state) do
    fps = trunc(@base_fps * multiplier)
    text = ~s(FPS mulitplier: #{multiplier} / FPS: #{fps})

    graph =
      state.graph
      |> Graph.modify(:fps_multiplier_text, &text(&1, text, []))
      |> push_graph()

    send_event({:fps, fps})
    {:stop, %{state | graph: graph, fps: fps}}
  end
end
