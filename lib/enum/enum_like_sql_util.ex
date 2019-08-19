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
    |> Enum.group_by(fn map ->
      group_by_key_list
      |> Enum.map(fn key -> map[key] end)
    end)
    |> Map.to_list()
    |> Enum.map(fn group_by_result ->
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
    initial_result =
      sum_key_list
      |> Enum.reduce(%{}, fn key, initial_result -> Map.put(initial_result, key, 0) end)

    sum_result_maps =
      group_by_results
      |> Enum.map(fn group_by_result ->
        {group_by_keys_map, maps} = group_by_result

        sum_result_map =
          maps
          |> Enum.reduce(initial_result, fn map, result_map ->
            sum_tmp_map =
              sum_key_list
              |> Enum.reduce(result_map, fn key, tmp_map ->
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
    initial_result =
      count_key_list
      |> Enum.reduce(%{}, fn key, initial_result -> Map.put(initial_result, key, 0) end)

    count_result_maps =
      group_by_results
      |> Enum.map(fn group_by_result ->
        {group_by_keys_map, maps} = group_by_result
        # 件数をカウント
        # *の件数（mapの単純な総件数）
        all_count =
          maps
          |> Enum.count()

        count_map = %{all_count: all_count}

        # 指定カラムのnot nullの件数（SQL仕様）
        col_count_map =
          count_key_list
          |> Enum.reduce(count_map, fn count_key, count_map ->
            col_count =
              maps
              |> Enum.count(fn map -> map[count_key] != nil end)

            Map.put(count_map, count_key, col_count)
          end)

        count_map =
          count_map
          |> Map.merge(col_count_map)

        {group_by_keys_map, count_map}
      end)
  end

  @doc """



  """
  @doc """
  親モデルと子モデルのリストおよび、紐付けに使うassociation_keyword_listを渡すことで
  preloadと同じ構造を返す
  ※現状は子のリスト内はstructureではなく__meta__をもつMapとなる為、厳密には同じ構造ではないので注意

  :has_many accociationのtype  現時点ではhas_manyのケースのみ対応
  association_keyword_list 親子モデルを紐付けるキーの対応　[{親キー項目: :子キー項目}, ...]
  parents　親スキーマのリスト(MapリストはNG)
  childs 子スキーマのリスト(MapリストはNG)
  :childs 親スキーマに付け加える子スキーマリストの項目名(atomで指定)


  ```
  iex(1)> association_keyword_list = [id: :parent_id]
  iex(2)> EnumLikeSqlUtil.dynamic_preload(:has_many, association_keyword_list, parents, childs, :childs)
  [
   %App.Parent{
     id: 1,
     aaa: aaa,
     bbb: bbb,
    childs: [
             %{
              id: 1
              parent_id: 1
               ccc: cccc,
               ddd: dddd
              },
             ....
            ]
    },
     ....
  ]

  ```

  """
  @spec dynamic_preload(Atom, [Keyword], List, List, Atom) :: List
  def dynamic_preload(:has_many, associate_keyword_list, parent_list, child_list, child_name_atom)
      when is_list(associate_keyword_list) and is_list(parent_list) and is_list(child_list) and
             is_atom(child_name_atom) do
    associate_key_list =
      associate_keyword_list
      |> Enum.map(fn associate_keyword ->
        {p, c} = associate_keyword
        c
      end)

    group_by_list =
      child_list
      |> Enum.map(fn child -> Map.from_struct(child) end)
      |> EnumLikeSqlUtil.group_by(associate_key_list)

    parent_list
    |> Enum.map(fn parent ->
      parent_map = Map.from_struct(parent)

      key_map =
        associate_keyword_list
        |> Enum.reduce(%{}, fn associate_keyword, acc ->
          {p, c} = associate_keyword

          acc
          |> Map.put(c, parent_map[p])
        end)

      child_key_value =
        group_by_list
        |> Enum.find(fn group_by_key_value ->
          {k, v} = group_by_key_value
          k == key_map
        end)

      {k, v} = child_key_value

      parent
      |> Map.put(child_name_atom, v)
    end)
  end
end
