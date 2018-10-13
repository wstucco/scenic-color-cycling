defmodule ColorCycling.Component.ColorCycling do
  use ScenicME.Component
  alias Scenic.Graph

  alias ScenicME.Asset

  alias ColorCycling.Component.ColorCycling.{
    Nav,
    Palette
  }

  alias ColorCycling.Palette, as: PaletteManager

  import Scenic.Components, only: [{:checkbox, 3}]
  import Scenic.Primitives, only: [{:rect, 3}, {:group, 3}, {:update_opts, 2}]
  import ScenicME.Helpers

  @frames 6

  def verify(scene) when is_atom(scene), do: {:ok, scene}
  def verify({scene, _} = data) when is_atom(scene), do: {:ok, data}
  def verify(_), do: :invalid_data

  def init(data, opts, _parent) do
    {width, height} = viewport_size(opts[:viewport])

    graph =
      Graph.build()
      |> group(
        fn
          g ->
            g
            |> rect(
              {width, height},
              fill: {:image, "hash"},
              translate: {0, 0},
              id: :image
            )
        end,
        []
      )
      |> rect({640, 480}, translate: {0, 480}, fill: :black)
      |> checkbox({"Color blending", true}, id: :color_blending, t: {374, 510})
      |> Palette.add_to_graph([], id: :palette, t: {374, 530})
      |> Nav.add_to_graph(data, translate: {640, 0})
      |> push_graph()

    {:ok,
     %{
       graph: graph,
       hash: nil,
       cycles: [],
       color_blending:
         Application.get_application(__MODULE__)
         |> Application.get_env(:color_blending, true)
     }}
  end

  def animation_frame(
        %{frame: frame},
        %{png: png, cycles: cycles} = state
      )
      when rem(frame, @frames) == 0 do
    palette =
      png.palette
      |> PaletteManager.cycle(cycles)

    state =
      state
      |> replace_image_and_palette(png, palette)

    {:noreply, state}
  end

  def animation_frame(
        %{frame: frame},
        %{png: png, cycles: cycles, color_blending: blend} = state
      )
      when blend == true do
    p = rem(frame, @frames) / @frames

    palette =
      png.palette
      |> PaletteManager.cycle(cycles)
      |> PaletteManager.fade(png.palette, p)

    state =
      state
      |> replace_image_and_palette(png, palette)
      |> Map.put(:png, png)

    {:noreply, state}
  end

  def animation_frame(_sc_state, state), do: {:noreply, state}

  def filter_event({:value_changed, :nav, id}, _, state) do
    state[:hash]
    |> Scenic.Cache.release()

    {:ok, hash} = load_assets(Asset.image("#{String.downcase(id)}.png"))

    {:ok, cycles} =
      File.read!(Asset.image("#{String.downcase(id)}.json"))
      |> Jason.decode(keys: :atoms)

    png = PNG.parse(Scenic.Cache.get!(hash))

    state =
      state
      |> replace_image_and_palette(png, png.palette)

    {:stop, %{state | png: png, cycles: cycles, hash: hash}}
  end

  def filter_event({:value_changed, :color_blending, blend}, _, state) do
    Application.get_application(__MODULE__)
    |> Application.put_env(:color_blending, blend)

    {:stop, %{state | color_blending: blend}}
  end

  def filter_event(msg, _from, state) do
    {:continue, msg, state}
  end

  def handle_info({:release_cache, hash}, state) do
    Scenic.Cache.release(hash)
    {:noreply, state}
  end

  defp replace_image_and_palette(state, png, palette) do
    png = PNG.replace_palette(png, palette)

    {graph, hash} =
      state.graph
      |> update_palette(palette)
      |> update_image(png)

    if hash != state.hash do
      # delay releasing the image blob in cache by 50ms
      # it could be faster than scenic drawing the new one
      Process.send_after(self(), {:release_cache, state.hash}, 20)
    end

    state
    |> Map.put(:graph, graph)
    |> Map.put(:hash, hash)
    |> Map.put(:png, png)
  end

  defp update_palette(graph, palette) do
    Palette.set_palette(palette)
    graph
  end

  defp update_image(graph, png) do
    {:ok, hash} =
      PNG.write(png)
      |> Scenic.Cache.Hash.binary!(:sha)
      |> Scenic.Cache.put(PNG.write(png))

    graph =
      graph
      |> Graph.modify(
        :image,
        &update_opts(&1,
          fill: {:image, hash}
        )
      )
      |> push_graph()

    {graph, hash}
  end
end
