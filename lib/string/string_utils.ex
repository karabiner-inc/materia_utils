defmodule MateriaUtils.String.StringUtil do

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

end
