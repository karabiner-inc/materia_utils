defmodule MateriaUtils.String.StringUtil do
  @moduledoc false
  @doc """

  normalize labels

  iex(1)> MateriaUtils.String.StringUtil.japanese_normalize("AZＡＺazａｚあん アンｱﾝ 　09０９漢字%％")
  "azazazazｱﾝｱﾝｱﾝ0909漢字%%"

  """
  @spec japanese_normalize(String) :: String
  def japanese_normalize(string) do
    string
    |> Mojiex.convert({:zs, :hs})
    |> String.replace(" ", "")
    |> Mojiex.convert({:hg, :kk})
    |> Mojiex.convert({:zk, :hk})
    |> Mojiex.convert({:ze, :he})
    |> String.downcase()
  end

  @doc """
  iex(1)> MateriaUtils.String.StringUtil.is_empty(nil)
  true
  iex(2)> MateriaUtils.String.StringUtil.is_empty("")
  true
  iex(3)> MateriaUtils.String.StringUtil.is_empty([])
  true
  iex(4)> MateriaUtils.String.StringUtil.is_empty(%{})
  true
  iex(5)> MateriaUtils.String.StringUtil.is_empty("Materia")
  false
  """
  def is_empty(value) do
    _ =
      cond do
        is_nil(value) -> true
        value == "" -> true
        value == [] -> true
        value == %{} -> true
        true -> false
      end
  end
end
