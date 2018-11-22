defmodule MateriaUtils.Ecto.EctoUtil do
  @moduledoc """
  Ecto関連の操作機能
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
end
