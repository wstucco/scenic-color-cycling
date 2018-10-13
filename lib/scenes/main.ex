defmodule ColorCycling.Scene.Main do
  @moduledoc """
  Sample splash scene.

  This scene demonstrate a very simple animation and transition to another scene.

  It also shows how to load a static texture and paint it into a rectangle.
  """

  use ScenicME.Scene
  alias Scenic.Graph

  alias ColorCycling.Component.{
    ColorCycling,
    FPS,
    FPSMultiplier
  }

  @graph Graph.build()

  # --------------------------------------------------------
  def init({_first_scene, _opts}) do
    # Timer.start(2)

    graph =
      @graph
      |> ColorCycling.add_to_graph(__MODULE__)
      |> FPSMultiplier.add_to_graph(__MODULE__, t: {20, 500})
      |> FPS.add_to_graph(__MODULE__, t: {20, 550})
      |> push_graph()

    {:ok, %{graph: graph}}
  end
end
