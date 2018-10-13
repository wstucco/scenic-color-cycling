#
#  Created by Boyd Multerer July 15, 2018.
#  Copyright © 2018 Kry10 Industries. All rights reserved.
#

defmodule ColorCycling.Component.Input.Dropdown do
  @moduledoc false

  use Scenic.Component, has_children: false

  alias Scenic.Graph
  alias Scenic.ViewPort
  alias Scenic.Primitive.Style.Theme
  import Scenic.Primitives

  # import IEx

  @default_width 160
  @default_height 30
  @default_direction :down

  @default_font :roboto
  @default_font_size 20

  @drop_click_window_ms 400

  @caret {{0, 0}, {12, 0}, {6, 6}}
  @text_id :__dropbox_text__
  @caret_id :__caret__
  @dropbox_id :__dropbox__
  @button_id :__dropbox_btn__

  @rotate_neutral :math.pi() / 2
  @rotate_down 0
  @rotate_up :math.pi()

  # --------------------------------------------------------
  def info(data) do
    """
    #{IO.ANSI.red()}Dropdown data must be: {items, initial}
    #{IO.ANSI.yellow()}Received: #{inspect(data)}
    #{IO.ANSI.default_color()}
    """
  end

  # --------------------------------------------------------
  def verify({items, initial} = data) when is_list(items) do
    (Enum.all?(items, &verify_item(&1)) &&
       Enum.find_value(items, false, fn {_, id} -> id == initial end))
    |> case do
      true -> {:ok, data}
      _ -> :invalid_data
    end
  end

  def verify(_), do: :invalid_data

  # --------------------------------------------------------
  defp verify_item({text, _}) when is_bitstring(text), do: true
  defp verify_item(_), do: false

  # --------------------------------------------------------
  # credo:disable-for-next-line Credo.Check.Refactor.CyclomaticComplexity
  def init({items, initial_id}, opts) do
    IO.inspect(opts)
    id = opts[:id]
    styles = opts[:styles]

    # theme is passed in as an inherited style
    theme =
      (styles[:theme] || Theme.preset(:dark))
      |> Theme.normalize()

    width = styles[:width] || styles[:w] || @default_width
    height = styles[:height] || styles[:h] || @default_height
    # alignment = opts[:align] || opts[:a] || @default_alignment

    # get style args
    font = styles[:font] || @default_font
    font_size = styles[:font_size] || @default_font_size

    # get the initial text
    initial_text =
      Enum.find_value(items, "", fn
        {text, ^initial_id} -> text
        _ -> false
      end)

    # calculate the drop box measures
    item_count = Enum.count(items)
    drop_height = item_count * height

    # get the drop direction
    direction = styles[:direction] || @default_direction

    # calculate the where to put the drop box. Depends on the direction
    translate_menu =
      case direction do
        :down -> {0, height + 1}
        :up -> {0, height * -item_count - 1}
      end

    # get the direction to rotate the caret
    rotate_caret =
      case direction do
        :down -> @rotate_down
        :up -> -@rotate_up
      end

    graph =
      Graph.build(font: font, font_size: font_size)
      |> rect({width, height}, fill: theme.background, stroke: {2, theme.border})
      |> text(initial_text,
        fill: theme.text,
        translate: {8, height * 0.7},
        text_align: :left,
        id: @text_id
      )
      |> triangle(@caret,
        fill: theme.text,
        translate: {width - 18, height * 0.5},
        pin: {6, 0},
        rotate: @rotate_neutral,
        id: @caret_id
      )

      # an invisible rect for hit-test purposes
      |> rect({width, height}, id: @button_id)

      # the drop box itself
      |> group(
        fn g ->
          g = rect(g, {width, drop_height}, fill: theme.background, stroke: {2, theme.border})

          {g, _} =
            Enum.reduce(items, {g, 0}, fn {text, id}, {g, i} ->
              g =
                group(
                  g,
                  # credo:disable-for-next-line Credo.Check.Refactor.Nesting
                  fn g ->
                    rect(
                      g,
                      {width, height},
                      fill:
                        if id == initial_id do
                          theme.active
                        else
                          theme.background
                        end,
                      id: id
                    )
                    |> text(text,
                      fill: theme.text,
                      text_align: :left,
                      translate: {8, height * 0.7}
                    )
                  end,
                  translate: {0, height * i}
                )

              {g, i + 1}
            end)

          g
        end,
        translate: translate_menu,
        id: @dropbox_id,
        hidden: true
      )

    state = %{
      graph: graph,
      selected_id: initial_id,
      theme: theme,
      id: id,
      down: false,
      hover_id: nil,
      items: items,
      drop_time: 0,
      rotate_caret: rotate_caret
    }

    push_graph(graph)

    {:ok, state}
  end

  # ============================================================================
  # tracking when the dropdown is UP

  # --------------------------------------------------------
  def handle_input({:cursor_enter, _uid}, %{id: id}, %{down: false} = state) do
    {:noreply, %{state | hover_id: id}}
  end

  # --------------------------------------------------------
  def handle_input({:cursor_exit, _uid}, _context, %{down: false} = state) do
    {:noreply, %{state | hover_id: nil}}
  end

  # --------------------------------------------------------
  def handle_input(
        {:cursor_button, {:left, :press, _, _}},
        %{id: @button_id} = context,
        %{down: false, graph: graph, rotate_caret: rotate_caret} = state
      ) do
    # capture input
    ViewPort.capture_input(context, [:cursor_button, :cursor_pos])

    # drop the menu
    graph =
      graph
      |> Graph.modify(@caret_id, &update_opts(&1, rotate: rotate_caret))
      |> Graph.modify(@dropbox_id, &update_opts(&1, hidden: false))
      |> push_graph()

    state =
      state
      |> Map.put(:down, true)
      |> Map.put(:drop_time, :os.system_time(:milli_seconds))
      |> Map.put(:graph, graph)

    {:noreply, state}
  end

  # ============================================================================
  # tracking when the dropdown is DOWN

  # --------------------------------------------------------
  def handle_input(
        {:cursor_enter, _uid},
        %{id: id},
        %{down: true, items: items, graph: graph, selected_id: selected_id, theme: theme} = state
      ) do
    # set the appropriate hilighting for each of the items
    graph =
      update_highlighting(graph, items, selected_id, id, theme)
      |> push_graph

    {:noreply, %{state | hover_id: id, graph: graph}}
  end

  # --------------------------------------------------------
  def handle_input(
        {:cursor_exit, _uid},
        _context,
        %{down: true, items: items, graph: graph, selected_id: selected_id, theme: theme} = state
      ) do
    # set the appropriate hilighting for each of the items
    graph =
      update_highlighting(graph, items, selected_id, nil, theme)
      |> push_graph

    {:noreply, %{state | hover_id: nil, graph: graph}}
  end

  # --------------------------------------------------------
  # the mouse is pressed outside of the dropdown when it is down.
  # immediately close the dropdown and allow the event to continue
  def handle_input(
        {:cursor_button, {:left, :press, _, _}},
        %{id: nil} = context,
        %{
          down: true,
          items: items,
          theme: theme,
          selected_id: selected_id
        } = state
      ) do
    # release the input capture
    ViewPort.release_input(context, [:cursor_button, :cursor_pos])

    graph =
      state.graph
      # restore standard highliting
      |> update_highlighting(items, selected_id, nil, theme)
      # raise the dropdown
      |> Graph.modify(@caret_id, &update_opts(&1, rotate: @rotate_neutral))
      |> Graph.modify(@dropbox_id, &update_opts(&1, hidden: true))
      # push to the viewport
      |> push_graph()

    {:noreply, %{state | down: false, graph: graph}}
  end

  # --------------------------------------------------------
  # clicking the button when down, raises it back up without doing anything else
  def handle_input(
        {:cursor_button, {:left, :release, _, _}},
        %{id: @button_id} = context,
        %{
          down: true,
          drop_time: drop_time,
          theme: theme,
          items: items,
          graph: graph,
          selected_id: selected_id
        } = state
      ) do
    if :os.system_time(:milli_seconds) - drop_time <= @drop_click_window_ms do
      # we are still in the click window, leave the menu down.
      {:noreply, state}
    else
      # we are outside the window, raise it back up
      graph =
        graph
        |> update_highlighting(items, selected_id, nil, theme)
        |> Graph.modify(@caret_id, &update_opts(&1, rotate: @rotate_neutral))
        |> Graph.modify(@dropbox_id, &update_opts(&1, hidden: true))
        |> push_graph()

      # release the input capture
      ViewPort.release_input(context, [:cursor_button, :cursor_pos])

      {:noreply, %{state | down: false, hover_id: nil, graph: graph}}
    end
  end

  # --------------------------------------------------------
  # the button is released outside the dropdown space
  def handle_input(
        {:cursor_button, {:left, :release, _, _}},
        %{id: nil} = context,
        %{
          down: true,
          items: items,
          theme: theme,
          selected_id: selected_id
        } = state
      ) do
    # release the input capture
    ViewPort.release_input(context, [:cursor_button, :cursor_pos])

    graph =
      state.graph
      # restore standard highliting
      |> update_highlighting(items, selected_id, nil, theme)
      # raise the dropdown
      |> Graph.modify(@caret_id, &update_opts(&1, rotate: @rotate_neutral))
      |> Graph.modify(@dropbox_id, &update_opts(&1, hidden: true))
      # push to the viewport
      |> push_graph()

    {:noreply, %{state | down: false, graph: graph}}
  end

  # --------------------------------------------------------
  # the button is realeased over an item in dropdown
  def handle_input(
        {:cursor_button, {:left, :release, _, _}},
        %{id: item_id} = context,
        %{
          down: true,
          id: id,
          items: items,
          theme: theme
        } = state
      ) do
    # release the input capture
    ViewPort.release_input(context, [:cursor_button, :cursor_pos])

    # send the value_changed message
    send_event({:value_changed, id, item_id})

    # find the newly selected item's text
    {text, _} = Enum.find(items, fn {_, id} -> id == item_id end)

    graph =
      state.graph
      # update the main button text
      |> Graph.modify(@text_id, &text(&1, text))
      # restore standard highliting
      |> update_highlighting(items, item_id, nil, theme)
      # raise the dropdown
      |> Graph.modify(@caret_id, &update_opts(&1, rotate: @rotate_neutral))
      |> Graph.modify(@dropbox_id, &update_opts(&1, hidden: true))
      # push to the viewport
      |> push_graph()

    {:noreply, %{state | down: false, graph: graph, selected_id: item_id}}
  end

  # ============================================================================
  # unhandled input

  # --------------------------------------------------------
  def handle_input(_event, _context, state) do
    {:noreply, state}
  end

  # ============================================================================
  # internal

  defp update_highlighting(graph, items, selected_id, hover_id, theme) do
    # set the appropriate hilighting for each of the items
    Enum.reduce(items, graph, fn
      # this is the item the user is hovering over
      {_, ^hover_id}, g ->
        Graph.modify(g, hover_id, &update_opts(&1, fill: theme.thumb))

      # this is the currently selected item
      {_, ^selected_id}, g ->
        Graph.modify(g, selected_id, &update_opts(&1, fill: theme.active))

      # not selected, not hovered over
      {_, regular_id}, g ->
        Graph.modify(g, regular_id, &update_opts(&1, fill: theme.background))
    end)
  end
end
