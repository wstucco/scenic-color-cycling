defmodule ScenicME.Matrix do
  @matrix_identity <<
    1.0::float-size(32)-native,
    0.0::float-size(32)-native,
    0.0::float-size(32)-native,
    0.0::float-size(32)-native,
    0.0::float-size(32)-native,
    1.0::float-size(32)-native,
    0.0::float-size(32)-native,
    0.0::float-size(32)-native,
    0.0::float-size(32)-native,
    0.0::float-size(32)-native,
    1.0::float-size(32)-native,
    0.0::float-size(32)-native,
    0.0::float-size(32)-native,
    0.0::float-size(32)-native,
    0.0::float-size(32)-native,
    1.0::float-size(32)-native
  >>

  def identity do
    @matrix_identity
  end

  def flip do
    matrix({-1.0, 0}, {1, 1})
  end

  defp matrix({v0x, v0y}, {v1x, v1y}) do
    <<
      v0x::float-size(32)-native,
      v0y::float-size(32)-native,
      0.0::float-size(32)-native,
      0.0::float-size(32)-native,
      v1x::float-size(32)-native,
      v1y::float-size(32)-native,
      0.0::float-size(32)-native,
      0.0::float-size(32)-native,
      0.0::float-size(32)-native,
      0.0::float-size(32)-native,
      1.0::float-size(32)-native,
      0.0::float-size(32)-native,
      0.0::float-size(32)-native,
      0.0::float-size(32)-native,
      0.0::float-size(32)-native,
      1.0::float-size(32)-native
    >>
  end

  defp matrix({v0x, v0y, v0z}, {v1x, v1y, v1z}, {v2x, v2y, v2z}) do
    <<
      v0x::float-size(32)-native,
      v0y::float-size(32)-native,
      v0z::float-size(32)-native,
      0.0::float-size(32)-native,
      v1x::float-size(32)-native,
      v1y::float-size(32)-native,
      v1z::float-size(32)-native,
      0.0::float-size(32)-native,
      v2x::float-size(32)-native,
      v2y::float-size(32)-native,
      v2z::float-size(32)-native,
      0.0::float-size(32)-native,
      0.0::float-size(32)-native,
      0.0::float-size(32)-native,
      0.0::float-size(32)-native,
      1.0::float-size(32)-native
    >>
  end
end
