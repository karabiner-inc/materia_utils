defmodule MateriaUtils.Ecto.EctoUtil do
  @moduledoc """
  Ecto関連の操作機能


  ヒストリカルテーブルに対して、現在断面や未来の履歴を返す共通実装を含む

  ヒストリカルテーブルは必ずレコードの有効時刻を表す
  start_datetime、end_datetimeを持つテーブルであること。
  また、同一データ同士でstard_datetimeとend_datetimeの期間重複がないことが前提となる。

  """
  import Ecto.Query, warn: false

  @doc """
  SQL直接実行

  EctoのSQLビルダを使用せずにSQLを直接実行する
  Ecto.Adapters.SQL.query()のWrapper関数
  戻り値を[%{row1},%{row2}...]形式で返す。

  ## Examples
  ```
  # iex> EctoUtil.query(MyApp.Repo, "select * from users", params)
  # [${id: => 1, name: => "userA name" },${id: => 2, name: => "userB name" }]
  ```

  """
  @spec query(Repo, string, [list]) :: [list]
  def query(repo, sql, params) do
    Ecto.Adapters.SQL.query(repo, sql, params)
    |> result_to_map_list()
  end

  @doc """
  汎用Selectエンドポイント用
  汎用検索向けなのでロックは取らない

  ## パラメータ

    - params: where句で使用したいパラメータ

  ## Examples

　  POSTで以下のparamsが指定される想定
    and もしくは orはマップのリストで指定する
    and もしくは orが必要ない場合は指定しなくてよい

    ```
    params = {
        "and": [{"stock_id": 1}, {"purchase_detail_id": 3}],
        "or": [{"status": 1}, {"status": 3}]
    }
    ```

    上記の例で実行されるクエリのWHERE条件
    ```
     WHERE ((s0.`status` = ?) OR (s0.`status` = ?)) AND ((s0.`stock_id` = ?) AND (s0.`purchase_detail_id` = ?))
    ```

  """
  @spec select_by_param(Repo, Ecto.Schema, [list]) :: [list]
  def select_by_param(repo, schema, params) do

    #汎用検索向けなのでロックは取らない
    query = from(t in schema)
    or_list =
        if params["or"] != nil do
          params["or"]
        else
          []
        end
    query = or_list
    |> Enum.reduce(query, fn(param, query) ->
        keys = Map.keys(param)
        key = List.first(keys)
        or_keyword = [{String.to_atom(key), Map.get(param, key)}]
        or_where(query, ^or_keyword)
    end)
    and_list =
    if  params["and"] != nil do
      params["and"]
      |> Enum.map(fn(param) ->
        keys = Map.keys(param)
        key = List.first(keys)
     {String.to_atom(key), Map.get(param, key)}
    end)
    else
      []
    end
    query = query
    |> where(^and_list)
    repo.all(query)

  end

  defp result_to_map_list(nil) do
    #戻りが無いSQLの場合、nilで処理する
    nil
  end
  defp result_to_map_list({:error, error}) do
    #エラーはスルー
    {:error, error}
  end

  defp result_to_map_list({:ok, result}) do

    columns = result.columns
    case columns do
      nil ->
        [num_rows: result.num_rows]
      _ ->
        rows = result.rows
        list_maps = Enum.map(rows, fn row -> row_columns_to_map(row, columns) end)
    end

  end

  defp row_columns_to_map(row, columns) do
    map_result =
      Enum.map(Enum.with_index(row, 0), fn {k, i} -> [Enum.at(columns, i), k] end)
      |> Enum.map(fn [a, b] -> {String.to_atom(a), convert(b)} end)
      |> Map.new()
  end

  def convert({{year, month, day}, {hour, minites, sec, msec}}) do
    #日時解釈できるものはDateTimeに変換
    Timex.to_datetime({{year, month, day}, {hour, minites, sec, msec}})
  end

  def convert(attr) do
    attr
  end

  @doc """
  ヒストリカルテーブル用のSelectエンドポイント用

  対処となるRepo,スキーマ及び
  基準となる時刻と検索キーをキーワドリスト[{k, v}]形式で指定すると
  履歴が挿入されたヒストリカルテーブルから基準時刻時点の断面データを返す


  ###Example

  iex(1)> MateriaUtils.Ecto.EctoUtil.list_current_history(MateriaCommerce.Test.Repo, MateriaCommerce.Products.Item, Timex.now(), [{:item_code, "ICZ1000"}])


  """
  @spec list_current_history(Repo, Ecto.Schema, DateTime, [Keyword]) :: List
  def list_current_history(repo, schema, base_datetime, keyword_list) do
    # 期間の検索条件付与
    sql = schema
    |> where([s], s.start_datetime <= ^base_datetime and s.end_datetime >= ^base_datetime)
    |> add_pk(keyword_list)
    |> lock("FOR UPDATE")
    |> repo.all()

  end

  @doc """
  ヒストリカルテーブル用のSelectエンドポイント用

  対処となるRepo,スキーマ及び
  基準となる時刻と検索キーをキーワドリスト[{k, v}]形式で指定すると
  履歴が挿入されたヒストリカルテーブルから基準時刻から未来の予定として登録された履歴の一覧を返す
  履歴更新時に先日付のデータをクリアする用途を想定する為、
  statt_datetime == base_datetime
  のデータを含む

  ###Example

  iex(1)> MateriaUtils.Ecto.EctoUtil.list_future_histories(MateriaCommerce.Test.Repo, MateriaCommerce.Products.Item, Timex.now(), [{:item_code, "ICZ1000"}])


  """
  @spec list_future_histories(Repo, Ecto.Schema, DateTime, [Keyword]) :: List
  def list_future_histories(repo, schema, base_datetime, keyword_list) do
    sql = schema
    |> where([s], s.start_datetime >= ^base_datetime)
    |> add_pk(keyword_list)
    |> lock("FOR UPDATE")
    |> repo.all()
  end

  @doc """
  ヒストリカルテーブル用の更新エンドポイント用

  対処となるRepo,スキーマ及び
  基準となる時刻と検索キーをキーワドリスト[{k, v}]形式で指定すると
  履歴が挿入されたヒストリカルテーブルから基準時刻から未来の予定として登録された履歴を削除する。
  データの更新用途を想定する為、
  statt_datetime == base_datetime
  のデータを含む

  ###Example

  iex(1)> base_datetime = MateriaUtils.Calendar.CalendarUtil.parse_iso_extended_z("2018-12-17 09:00:00Z")
  iex(2)> MateriaUtils.Ecto.EctoUtil.delete_future_histories(MateriaCommerce.Test.Repo, MateriaCommerce.Products.Item, base_datetime, [{:item_code, "ICZ1000"}])

  """
  @spec delete_future_histories(Repo, Ecto.Schema, DateTime, [Keyword]) :: {integer(), nil | [term()]}
  def delete_future_histories(repo, schema, base_datetime, keyword_list) do
    sql = schema
    |> where([s], s.start_datetime >= ^base_datetime)
    |> add_pk(keyword_list)
    |> repo.delete_all()
  end

  @doc """
  ヒストリカルテーブル用のSelectエンドポイント用

  対処となるRepo,スキーマ及び
  基準となる時刻と検索キーをキーワドリスト[{k, v}]形式で指定すると
  履歴が挿入されたヒストリカルテーブルから基準時刻より過去の履歴として登録された履歴の一覧を返す
  statt_datetime == base_datetime
  のデータを含まない

  ###Example

  iex(1)> MateriaUtils.Ecto.EctoUtil.list_past_histories(MateriaCommerce.Test.Repo, MateriaCommerce.Products.Item, Timex.now(), [{:item_code, "ICZ1000"}])


  """
  @spec list_past_histories(Repo, Ecto.Schema, DateTime, [Keyword]) :: List
  def list_past_histories(repo, schema, base_datetime, keyword_list) do
    sql = schema
    |> where([s], s.start_datetime < ^base_datetime)
    |> add_pk(keyword_list)
    |> lock("FOR UPDATE")
    |> repo.all()
  end

  @doc """
  query1 = schema |> select([s], [s.item_code, max(s.stard_datetime)]) |> from([s]) |> where([s], s.start_datetime < ^base_datetime) |> where(^[{:item_code, "ICZ1000"}])
  query2 = from(s in MateriaCommerce.Products.Item, join: s2 in subquery(query1))
  query2 = schema |> where(^[{:item_code, "ICZ1000"}])
  """
  #@spec list_recent_history(Repo, Ecto.Schema, DateTime, [Keyword]) :: List
  #def list_recent_history(repo, schema, base_datetime, keyword_list) do
  #  sql = schema
  #  |> where([s], s.start_datetime > ^base_datetime)
  #  |> add_pk(keyword_list)
  #  |> lock("FOR UPDATE")
  #  |> repo.all()
  #end

  @doc """
  MateriaUtils.Ecto.EctoUtil.list_recent_history(MateriaCommerce.Test.Repo, MateriaCommerce.Products.Item, Timex.now(), [{:item_code, "ICZ1000"}])
  """
  @spec list_recent_history(Repo, Ecto.Schema, DateTime, [Keyword]) :: List
  def list_recent_history(repo, schema, base_datetime, keyword_list) do
    table_name = Ecto.get_meta(struct(schema), :source)
    select_string = keyword_list
                    |> Enum.reduce(
                         "",
                         fn (keyword, acc) ->
                           {k, v} = keyword
                           if acc != "", do: "#{acc}, #{k}", else: "#{acc}#{k}"
                         end
                       )
    and_string = keyword_list
                 |> Enum.reduce(
                      "",
                      fn (keyword, acc) ->
                        {k, v} = keyword
                        if acc != "", do: "#{acc} and #{k} = '#{v}'", else: "#{acc}#{k} = '#{v}'"
                      end
                    )
    join_on_string = keyword_list
                     |> Enum.reduce(
                          "",
                          fn (keyword, acc) ->
                            {k, v} = keyword
                            "#{acc} and s1.#{k} = s2.#{k}"
                          end
                        )
    sql = "
      select
        *
      from
        (
          select
            *
          from
            #{table_name}
          where
            #{and_string}
        ) s1
        join(
          select
            #{select_string} ,max( start_datetime ) as start_datetime
          from
            #{table_name}
          where
            start_datetime < $1 and
            #{and_string}
          group by
            #{select_string}
        ) s2 on
        s1.start_datetime = s2.start_datetime
        #{join_on_string}"

    query(repo, sql, [base_datetime])
  end

  def add_pk(sql, key_word_list) do
    # 主キーの検索条件付与
    sql = [key_word_list]
    |> Enum.reduce(sql, fn(key_word, acc) ->
      acc
      |> where(^key_word)
    end)
  end
end
