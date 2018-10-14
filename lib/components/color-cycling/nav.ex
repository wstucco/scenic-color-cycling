defmodule ColorCycling.Component.ColorCycling.Nav do
  use Scenic.Component

  alias Scenic.Graph
  alias Scenic.Primitive.Style.Theme

  import Scenic.Primitives, only: [{:text, 3}, {:rect, 3}, {:update_opts, 2}]
  import ScenicME.Helpers

  # import IEx

  @items [
           {"Jungle Waterfall - Morning", "V08AM"},
           {"Seascape - Day", "V29"},
           {"Mountain Stream - Morning", "V19"},
           #  {"Winter Forest - Day", "V26"},
           {"Winter Forest - Snow", "V26SNOW"},
           {"Winter Forest - Dusk", "V26PM"},
           {"Jungle Waterfall - Rain", "V08RAIN"},
           {"Mountain Storm - Day", "V14"},
           {"Deep Forest - Day", "V30"},
           {"Highland Ruins - Rain", "V04"},
           {"Rough Seas - Day", "V07"},
           {"Crystal Caves - Day", "V20"},
           #  {"Haunted Castle Ruins - Morning", "V05AM"},
           {"Haunted Castle Ruins - Rain", "V05RAIN"},
           #  {"Haunted Castle Ruins - Dusk", "V05PM"},
           {"Jungle Waterfall - Night", "V08PM"},
           {"Mirror Pond - Rain", "V16RAIN"},
           {"Mountain Stream - Night", "V19AURA"},
           {"Aquarius - Day", "CORAL"},
           {"Harbor Town - Night", "V15"},
           {"Deep Forest - Rain", "V30RAIN"},
           {"Mountain Fortress - Dusk", "V02"},
           {"Water City Gates - Fog", "V28"},
           {"Seascape - Sunset", "V29PM"},
           {"Mirror Pond - Morning", "V16"},
           {"Island Fires - Dusk", "V01"},
           {"Forest Edge - Day", "V09"},
           {"Mirror Pond - Afternoon", "V16PM"},
           {"Jungle Waterfall - Afternoon", "V08"},
           {"Swamp Cathedral - Day", "V03"},
           {"Haunted Castle Ruins - Night", "V05HAUNT"},
           {"Deep Swamp - Day", "V10"},
           {"Approaching Storm - Day", "V11AM"},
           {"Pond Ripples - Dawn", "V13"},
           {"Ice Wind - Day", "V17"},
           {"Mountain Stream - Afternoon", "V19PM"},
           {"Desert - Heat Wave", "V25HEAT"},
           #  {"Desert - Day", "V25"},
           #  {"Desert - Dusk", "V25PM"},
           {"Magic Marsh Cave - Night", "V27"},
           {"Seascape - Fog", "V29FOG"}
         ]
         |> Enum.sort(fn {label0, _}, {label1, _} -> label0 <= label1 end)

  @initial_item "V08AM"

  @width 200
  @font_size 14
  @item_height @font_size + 4
  @theme Theme.preset(:dark) |> Theme.normalize()

  # --------------------------------------------------------
  def verify(scene) when is_atom(scene), do: {:ok, scene}
  def verify({scene, _} = data) when is_atom(scene), do: {:ok, data}
  def verify(_), do: :invalid_data

  # ----------------------------------------------------------------------------
  def init(_current_scene, opts) do
    {_, height} = viewport_size(opts[:viewport])

    graph =
      Graph.build(font_size: @font_size)
      |> rect({@width, height}, fill: {48, 48, 48})
      |> add_links(@initial_item)
      |> push_graph()

    send_event({:value_changed, :nav, @initial_item})

    {:ok, %{graph: graph, selected_id: @initial_item}}
  end

  def handle_input({:cursor_pos, {_x, y}}, _context, state) do
    highlight_hovered_item(state.graph, y)
    {:noreply, state}
  end

  def handle_input({:cursor_exit, _uid}, _context, state) do
    redraw_items(state.graph, state.selected_id)
    {:noreply, state}
  end

  def handle_input({:cursor_button, {:left, :press, 0, {_x, y}}}, _context, state) do
    selected_id = item_at(y)

    if selected_id != nil and selected_id != state.selected_id do
      graph = state.graph |> redraw_items(selected_id)
      send_event({:value_changed, :nav, selected_id})
      {:noreply, %{state | graph: graph, selected_id: selected_id}}
    else
      {:noreply, state}
    end
  end

  def handle_input(_message, _context, state) do
    {:noreply, state}
  end

  defp add_links(graph, selected_id) do
    @items
    |> Enum.with_index(1)
    |> Enum.reduce(graph, fn {{label, id}, index}, graph ->
      graph
      |> text(
        "#{label} - #{id}",
        translate: {10, @item_height * index},
        fill: if(id == selected_id, do: @theme.thumb, else: @theme.text),
        id: to_graph_id(id)
      )
    end)
  end

  defp redraw_items(graph, selected_id) do
    @items
    |> Enum.reduce(graph, fn
      {_label, id}, graph when id == selected_id ->
        graph
        |> Graph.modify(
          to_graph_id(id),
          &update_opts(&1,
            fill: @theme.thumb
          )
        )

      {_label, id}, graph ->
        graph
        |> Graph.modify(
          to_graph_id(id),
          &update_opts(&1,
            fill: @theme.text
          )
        )
    end)
    |> push_graph()
  end

  defp highlight_hovered_item(graph, y) do
    case item_at(y) do
      nil ->
        nil

      id ->
        graph
        |> Graph.modify(
          to_graph_id(id),
          &update_opts(&1,
            fill: @theme.thumb
          )
        )
        |> push_graph()
    end
  end

  defp item_at(y) do
    index = (y / @item_height) |> trunc

    case @items |> Enum.at(index) do
      nil ->
        nil

      {_label, id} ->
        id
    end

    # graph
    # |> Graph.reduce(nil, fn p, acc ->
    #   case Primitive.get_transform(p, :translate) do
    #     {_px, py} when py <= y ->
    #       p

    #     _ ->
    #       acc
    #   end
    # end)
  end

  defp to_graph_id(id) do
    "#{id}__text" |> String.to_atom()
  end
end
