defmodule ColorCycling.Palette do
  def cycle(palette, cycles) do
    cycles
    |> Enum.flat_map(&do_cycle(palette, &1))
    |> Enum.reduce(palette, &replace_colors/2)
  end

  def fade(dst, src, position) do
    src
    |> Enum.zip(dst)
    |> Enum.map(fn {{r0, g0, b0}, {r1, g1, b1}} ->
      {
        trunc(r0 + (r1 - r0) * position),
        trunc(g0 + (g1 - g0) * position),
        trunc(b0 + (b1 - b0) * position)
      }
    end)
  end

  defp do_cycle(
         palette,
         %{rate: rate, mode: 0, low: low, high: high}
       )
       when rate > 0 do
    slice =
      palette
      |> slice(low, high)

    slice
    |> Enum.slice(-1, 1)
    |> Kernel.++(slice |> Enum.drop(-1))
    |> Enum.with_index(low)
  end

  defp do_cycle(
         palette,
         %{rate: rate, mode: 2, low: low, high: high}
       )
       when rate > 0 do
    slice =
      palette
      |> slice(low, high)

    slice
    |> tl
    |> Kernel.++(slice |> Enum.slice(0, 1))
    |> Enum.with_index(low)
  end

  defp do_cycle(_palette, _cycle), do: []

  defp replace_colors({color, index}, palette) do
    List.replace_at(palette, index, color)
  end

  def slice(palette, low, high) do
    Enum.slice(palette, low, high - low + 1)
  end
end
