defmodule MateriaUtils.Enum.EnumLikeSqlUtil do
  @moduledoc """
  Enumでの集計をSQL構文に近い形で実行する為のユーティリティー

  基本的にまず、group_by関数で集計対象となるキーリストを作成してから
  後続の関数で合計、カウントなどの集計処理を行う。

  ### example
  ```
  map_list
  |> group_by([:key1, :key2])
  |> xxxx(params)
  ```

  """

  @doc """
  Enumに対して、集計したい要素のキーを渡すことで、キーリストを取得する。

  ```
  iex(1)> map_list = map_list = [%{key1: 1, key2: "aaa", key3: 100}, %{key1: 2, key2: "aaa", key3: 200}, %{key1: 1, key2: "aaa", key3: 150},]
  iex(2)> MateriaUtils.Enum.EnumLikeSqlUtil.group_by(map_list, [:key1, :key2])
  [
    {%{key1: 1, key2: "aaa"},
     [%{key1: 1, key2: "aaa", key3: 100}, %{key1: 1, key2: "aaa", key3: 150}]},
    {%{key1: 2, key2: "aaa"}, [%{key1: 2, key2: "aaa", key3: 200}]}
  ]
  ```

  """
  @spec group_by([Map], [String | Atom]) :: [Map]
  def group_by(maps, group_by_key_list) do

    maps
    |> Enum.group_by(fn(map) ->
      group_by_key_list
      |> Enum.map(fn(key) -> map[key] end)
    end)
    |> Map.to_list()
    |> Enum.map(fn(group_by_result) ->
      {group_value_list, maps} = group_by_result
      group_by_keys_map = Enum.zip(group_by_key_list, group_value_list) |> Enum.into(%{})
      {group_by_keys_map, maps}
    end)

  end

  @doc """
  group_by/2関数で取得した集計キーリストと、集計対象キーのリストを元に合計結果を算出する。

  以下のSQLの結果をエミュレートする場合、
  ```
  select sum(key3) from table group by (key1, key2);
  ```

  以下のように実装する。
  ```
  map_list
  |> group_by([key1, key2])
  |> sum([key3])
  ```

  ```
  iex(1)> map_list = map_list = [%{key1: 1, key2: "aaa", key3: 100}, %{key1: 2, key2: "aaa", key3: 200}, %{key1: 1, key2: "aaa", key3: 150},]
  iex(2)> map_list |> MateriaUtils.Enum.EnumLikeSqlUtil.group_by([:key1, :key2]) |> MateriaUtils.Enum.EnumLikeSqlUtil.sum([:key3])
  [%{key1: 1, key2: "aaa", key3: 250}, %{key1: 2, key2: "aaa", key3: 200}]
  ```

  """
  @spec sum([Map], [String | Atom]) :: [Map]
  def sum(group_by_results, sum_key_list) do


    initial_result = sum_key_list
    |> Enum.reduce(%{}, fn(key, initial_result) -> Map.put(initial_result, key, 0) end)

    sum_result_maps = group_by_results
    |> Enum.map(fn(group_by_result) ->
      {group_by_keys_map, maps} = group_by_result
      sum_result_map = maps
      |> Enum.reduce(initial_result, fn(map, result_map) ->
        sum_tmp_map = sum_key_list
        |> Enum.reduce(result_map, fn(key, tmp_map) ->
          Map.put(tmp_map, key, tmp_map[key] + map[key])
        end)
      end)
      Map.merge(group_by_keys_map, sum_result_map)
    end)

  end

# [
#  {%{"item_id" => 1}, %{all_count: 1, picked_date: 0, picking_id: 3, status: 1}},
#  {%{"item_id" => 2}, %{all_count: 1, picked_date: 0, picking_id: 3, status: 1}}
# ]
# %{all_count: group_by_resultsのkey毎の総件数


@doc """
  group_by/2関数で取得した集計キーリストを元に件数結果を算出する。
  group_byで指定したキー条件に当てはまる全件をall_countとして返す。
  カウント対象キーリストを指定した場合、合わせて対象の項目がnilの件数を除いた有効件数を各項目のcountとして返す。

  以下のSQLの結果をエミュレートする場合、
  ```
  select cout(key3) from table group by (key1, key2);
  ```

  以下のように実装する。
  ```
  map_list
  |> group_by([key1, key2])
  |> count([key3])
  ```

  ```
  iex(1)> map_list = map_list = [%{key1: 1, key2: "aaa", key3: 100}, %{key1: 2, key2: "aaa", key3: 200}, %{key1: 1, key2: "aaa", key3: 150},]
  iex(2)> map_list |> MateriaUtils.Enum.EnumLikeSqlUtil.group_by([:key1, :key2]) |> MateriaUtils.Enum.EnumLikeSqlUtil.count()
  [
    {%{key1: 1, key2: "aaa"}, %{all_count: 2}},
    {%{key1: 2, key2: "aaa"}, %{all_count: 1}}
  ]
  iex(3)> map_list |> MateriaUtils.Enum.EnumLikeSqlUtil.group_by([:key1, :key2]) |> MateriaUtils.Enum.EnumLikeSqlUtil.count([:key3])
  [
    {%{key1: 1, key2: "aaa"}, %{all_count: 2, key3: 2}},
    {%{key1: 2, key2: "aaa"}, %{all_count: 1, key3: 1}}
  ]
  ```

  """
@spec count([Map], [String | Atom]) :: [Map]
def count(group_by_results, count_key_list \\ []) do

  # [%{picking_id: 4, shipping_id: 5}, %{*: 5}]
  initial_result = count_key_list
  |> Enum.reduce(%{}, fn(key, initial_result) -> Map.put(initial_result, key, 0) end)

  count_result_maps = group_by_results
  |> Enum.map(fn(group_by_result) ->
    {group_by_keys_map, maps} = group_by_result
    # 件数をカウント
    # *の件数（mapの単純な総件数）
    all_count = maps
    |> Enum.count()

    count_map = %{all_count: all_count}

    # 指定カラムのnot nullの件数（SQL仕様）
    col_count_map = count_key_list
    |> Enum.reduce(count_map, fn(count_key, count_map) ->
      col_count = maps
      |> Enum.count(fn(map) -> map[count_key] != nil end)
      Map.put(count_map, count_key, col_count)
    end)

    count_map = count_map
    |> Map.merge(col_count_map)

    {group_by_keys_map, count_map}

  end)

end

end
