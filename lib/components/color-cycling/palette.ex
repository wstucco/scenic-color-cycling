defmodule ColorCycling.Component.ColorCycling.Palette do
  use ScenicME.Component
  alias Scenic.Graph

  import Scenic.Primitives, only: [{:rect, 3}, {:group, 3}, {:update_opts, 2}]

  def verify(palette) when is_list(palette), do: {:ok, palette}
  def verify(scene) when is_atom(scene), do: {:ok, scene}
  def verify({scene, _} = data) when is_atom(scene), do: {:ok, data}
  def verify(_), do: :invalid_data

  def init(data, opts, _parent) do
    graph =
      Graph.build()
      |> group(&add_palette(&1, data), opts)
      |> push_graph()

    {:ok, %{graph: graph, palette: data, new_palette: data}}
  end

  def set_palette(pid, palette) when is_list(palette) do
    GenServer.cast(pid, {:set_palette, palette})
  end

  def handle_cast({:set_palette, palette}, state) do
    {:noreply, %{state | new_palette: palette}}
  end

  def animation_frame(_sc_state, %{graph: graph, palette: old, new_palette: new} = state)
      when old != new do
    send_event(:palette_request)

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

  def animation_frame(_sc_state, state) do
    send_event(:palette_request)
    {:noreply, state}
  end

  defp add_palette(group, data) do
    group
    |> grid()
    |> palette(data |> Enum.with_index())
  end

  defp grid(group) do
    0..255 |> Enum.reduce(group, &cell/2)
  end

  defp cell(i, group) do
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
  end

  defp palette(group, []) do
    0..255
    |> Enum.reduce(group, &modify_cell/2)
  end

  defp palette(group, data) do
    group =
      data
      |> Enum.reduce(group, &modify_cell/2)

    # in case PNG has a palette with less than 256 colors and the previous
    # one was larger, black out all the blocks that were filled with a color
    {_, len} = Enum.max_by(data, fn {_, i} -> i end)

    if len < 255 do
      len..255
      |> Enum.reduce(group, &modify_cell/2)
    else
      group
    end
  end

  defp modify_cell({color, i}, group) do
    group
    |> Graph.modify(
      "cell_#{i}" |> String.to_atom(),
      &update_opts(&1, fill: color)
    )
  end

  defp modify_cell(i, group) when is_number(i) do
    group
    |> Graph.modify(
      "cell_#{i}" |> String.to_atom(),
      &update_opts(&1, fill: :black)
    )
  end
end
