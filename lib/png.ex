defmodule PNG do
  defstruct [
    :width,
    :height,
    :length,
    :crc,
    :bit_depth,
    :color_type,
    :compression,
    :filter,
    :interlace,
    :palette,
    :chunks
  ]

  @png_header <<137::size(8), ?P, ?N, ?G, ?\r, ?\n, 26::size(8), ?\n>>
  @ihdr_header <<?I, ?H, ?D, ?R>>
  @plte_header <<?P, ?L, ?T, ?E>>

  def parse(
        @png_header <>
          <<
            length::size(32),
            @ihdr_header,
            width::size(32),
            height::size(32),
            bit_depth,
            color_type,
            compression_method,
            filter_method,
            interlace_method,
            crc::size(32),
            chunks::binary
          >>
      ) do
    png = %PNG{
      width: width,
      height: height,
      length: length,
      crc: crc,
      bit_depth: bit_depth,
      color_type: color_type,
      compression: compression_method,
      filter: filter_method,
      interlace: interlace_method,
      chunks: []
    }

    parse_chunks(chunks, png)
  end

  def write(%PNG{} = png) do
    content =
      png.chunks
      |> Enum.map(fn
        chunk ->
          content_length = byte_size(chunk.data)
          crc32 = :erlang.crc32(chunk.chunk_type <> chunk.data)

          <<
            content_length::integer-unit(1)-size(32),
            chunk.chunk_type::binary-size(4),
            chunk.data::binary,
            crc32::size(32)
          >>
      end)

    header = <<
      @png_header,
      png.length::integer-size(32),
      @ihdr_header,
      png.width::integer-size(32),
      png.height::integer-size(32),
      png.bit_depth::integer,
      png.color_type::integer,
      png.compression::integer,
      png.filter::integer,
      png.interlace::integer,
      png.crc::integer-size(32)
    >>

    content
    |> Enum.reduce(header, fn chunk, acc ->
      acc <> chunk
    end)
  end

  def replace_palette(%PNG{chunks: chunks} = png, palette) do
    index =
      chunks
      |> Enum.find_index(&(&1.chunk_type == @plte_header))

    plte =
      chunks
      |> Enum.at(index)

    data = for {r, g, b} <- palette, do: <<r::8, g::8, b::8>>, into: ""

    plte =
      plte
      |> Map.put(:data, data)
      |> Map.put(:crc, :erlang.crc32(@plte_header <> data))

    chunks =
      chunks
      |> List.replace_at(index, plte)

    png
    |> Map.put(:palette, palette)
    |> Map.put(:chunks, chunks)
  end

  def grayscale(%PNG{palette: palette} = png) do
    grayscale_palette =
      palette
      |> Enum.map(fn {r, g, b} ->
        c = ((r / 256 * 0.2126 + g / 256 * 0.7152 + b / 256 * 0.0722) * 256) |> trunc
        {c, c, c}
      end)

    png |> replace_palette(grayscale_palette)
  end

  def invert(%PNG{palette: palette} = png) do
    inverted_palette =
      palette
      |> Enum.map(fn {r, g, b} ->
        {255 - r, 255 - g, 255 - b}
      end)

    png |> replace_palette(inverted_palette)
  end

  defp parse_chunks(
         <<length::size(32), @plte_header, chunk_data::binary-size(length), crc::size(32),
           chunks::binary>>,
         png
       ) do
    chunk = %{
      length: length,
      chunk_type: @plte_header,
      data: chunk_data,
      crc: crc
    }

    png = %{png | chunks: [chunk | png.chunks], palette: read_palette(chunk_data)}

    parse_chunks(chunks, png)
  end

  defp parse_chunks(
         <<length::size(32), chunk_type::binary-size(4), chunk_data::binary-size(length),
           crc::size(32), chunks::binary>>,
         png
       ) do
    chunk = %{length: length, chunk_type: chunk_type, data: chunk_data, crc: crc}
    png = %{png | chunks: [chunk | png.chunks]}

    parse_chunks(chunks, png)
  end

  defp parse_chunks(<<>>, png) do
    %{png | chunks: Enum.reverse(png.chunks)}
  end

  defp read_palette(content) do
    read_palette(content, [])
  end

  # In the base case, we have a list of palette colors
  defp read_palette(<<>>, palette) do
    Enum.reverse(palette)
  end

  defp read_palette(<<red::size(8), green::size(8), blue::size(8), more_palette::binary>>, acc) do
    read_palette(more_palette, [{red, green, blue} | acc])
  end
end
