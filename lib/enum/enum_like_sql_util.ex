defmodule AppExUtils.Enum.EnumLikeSqlUtil do

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
#  %{all_count: 1, picking_date: 0, picking_id: 3, status: 1},
#  %{all_count: 1, picking_date: 0, picking_id: 4, status: 1}
# ]
# %{all_count: group_by_resultsのkey毎の総件数
def count(group_by_results, count_key_list \\ []) do

  # [%{picking_id: 4, shipping_id: 5}, %{*: 5}]
  initial_result = count_key_list
  |> Enum.reduce(%{}, fn(key, initial_result) -> Map.put(initial_result, key, 0) end)

  sum_result_maps = group_by_results
  |> Enum.map(fn(group_by_result) ->
    {group_by_keys_map, maps} = group_by_result
    # 件数をカウント
    # *の件数（mapの単純な総件数）
    all_count = maps
    |> Enum.count()

    count_map = %{all_count: all_count}

    # 指定カラムのnot nullの件数（SQL仕様）
    count_map = count_key_list
    |> Enum.reduce(count_map, fn(count_key, count_map) ->
      col_count = maps
      |> Enum.count(fn(map) -> map[count_key] != nil end)
      Map.put(count_map, count_key, col_count)
    end)

    Map.merge(group_by_keys_map, count_map)

  end)

end

end
