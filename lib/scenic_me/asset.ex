defmodule ScenicME.Asset do
  # @base_path :code.priv_dir(:sotb)

  def asset_path(path) do
    Path.join(base_path(), path)
  end

  def image_path(path) do
    ["static", "images", path]
    |> Path.join()
    |> asset_path()
  end

  def hash(path) do
    Scenic.Cache.Hash.file!(path, :sha)
  end

  defp base_path, do: :code.priv_dir(Application.get_application(__MODULE__))
end
