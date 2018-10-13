defmodule ColorCycling.Component.ColorCycling.Palette do
  use ScenicME.Component
  alias Scenic.Graph

  import Scenic.Primitives, only: [{:rect, 3}, {:group, 3}, {:update_opts, 2}]

  def verify(palette) when is_list(palette), do: {:ok, palette}
  def verify(scene) when is_atom(scene), do: {:ok, scene}
  def verify({scene, _} = data) when is_atom(scene), do: {:ok, data}
  def verify(_), do: :invalid_data

  def init(data, opts, _parent) do
    Process.register(self(), __MODULE__)

    graph =
      Graph.build()
      |> group(&add_palette(&1, data), opts)
      |> push_graph()

    {:ok, %{graph: graph, palette: data, new_palette: data}}
  end

  def set_palette(palette) when is_list(palette) do
    GenServer.cast(__MODULE__, {:set_palette, palette})
  end

  def handle_cast({:set_palette, palette}, state) do
    {:noreply, %{state | new_palette: palette}}
  end

  def animation_frame(_sc_state, %{graph: graph, palette: old, new_palette: new} = state)
      when old != new do
    palette =
      new
      |> Enum.with_index()
      |> Enum.filter(fn {color, i} ->
        Enum.at(old, i) != color
      end)

    graph =
      graph
      |> palette(palette)
      |> push_graph()

    {:noreply, %{state | graph: graph, palette: palette}}
  end

  def animation_frame(_sc_state, state), do: {:noreply, state}

  defp add_palette(group, data) do
    group
    # |> background()
    |> grid()
    |> palette(data |> Enum.with_index())
  end

  defp background(group) do
    group
    |> rect(
      {256, 256},
      fill: :black
    )
  end

  defp grid(group) do
    0..255
    |> Enum.reduce(group, fn i, group ->
      row = rem(i, 16)
      col = div(i, 16)
      x = 16 * row
      y = 16 * col

      group
      |> rect(
        {15, 15},
        fill: :black,
        t: {x, y},
        id: "cell_#{i}" |> String.to_atom()
      )
    end)
  end

  defp palette(group, []) do
    0..255
    |> Enum.reduce(group, fn i, group ->
      group
      |> Graph.modify(
        "cell_#{i}" |> String.to_atom(),
        &update_opts(&1, fill: :black)
      )
    end)
  end

  defp palette(group, data) do
    group =
      data
      |> Enum.reduce(group, fn {color, i}, group ->
        group
        |> Graph.modify(
          "cell_#{i}" |> String.to_atom(),
          &update_opts(&1, fill: color)
        )
      end)

    {_, len} = Enum.max_by(data, fn {_, i} -> i end)

    if len < 256 do
      len..255
      |> Enum.reduce(group, fn i, group ->
        group
        |> Graph.modify(
          "cell_#{i}" |> String.to_atom(),
          &update_opts(&1, fill: :black)
        )
      end)
    else
      group
    end
  end
end
