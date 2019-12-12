defmodule MateriaUtils.PagingUtil do
  @moduledoc false

  import Ecto.Query, warn: false
  alias MateriaUtils.PagingUtil
  alias MateriaUtils.String.StringUtil

  @doc """
    フィルター・ソート・ページングの共通処理｡
    * params["filter"] -> フィルタ用パラメータ
      - equal:   一致
        [%{"column_name" => "value"} ...]
      - between: 範囲指定
        [%{"column_name" => %{"from" => "value", "to" => "value"}} ...]
      - like:    曖昧検索
        [%{"column_name" => "value"} ...]

    * params["paging"] -> ページング用パラメータ
      - page:    取得ページNo
      - limit:   1ページの表示件数

    * params["order_by"] -> ソート用パラメータ
      - column:  対象カラム名
      - sorter:  ソート方法(asc, desc)
  """
  def list_results_filter_to_sort(query, params, repo) do
    all_result_count =
      query
      |> PagingUtil.set_filter(params["filter"])
      |> repo.all()
      |> Enum.count()

    query
    |> PagingUtil.set_filter(params["filter"])
    |> PagingUtil.set_sorter(params["order_by"])
    |> PagingUtil.set_limit_offset(params["paging"])
    |> repo.all()
    |> PagingUtil.convert_to_paging_results(all_result_count, params["paging"])
  end

  @doc """
    抽出結果
    all_result_count -> フィルター結果のすべての件数
    all_page_count -> 全ページ数
    current_page_no -> 取得ページ数
    data -> 取得結果
  """
  def convert_to_paging_results(results, all_result_count, paging) do
    %{
      all_result_count: all_result_count,
      all_page_count: PagingUtil.get_all_result_count(all_result_count, paging),
      current_page_no: PagingUtil.get_current_page_no(paging),
      data: results
    }
  end

  @doc false
  def set_sorter(query, order) do
    if PagingUtil.is_valid_check_sorter_params?(order) do
      set_order_by(query, String.to_atom(order["column"]), order["sorter"])
    else
      query
    end
  end

  @doc false
  def set_order_by(query, column, sorter) when sorter == "asc", do: order_by(query, asc: ^column)

  @doc false
  def set_order_by(query, column, sorter) when sorter == "desc", do: order_by(query, desc: ^column)

  @doc false
  def set_limit_offset(query, paging) do
    if PagingUtil.is_valid_check_offset_params?(paging) do
      offset = (paging["page"] - 1) * paging["limit"]

      query
      |> limit(^paging["limit"])
      |> offset(^offset)
    else
      query
    end
  end

  @doc false
  def set_filter(query, filter) do
    query
    |> set_filter_equal(filter)
    |> set_filter_between(filter)
    |> set_filter_like(filter)
  end

  @doc false
  def set_filter_equal(query, filter) do
    if PagingUtil.is_valid_check_filter_equal?(filter) do
      filter["equal"]
      |> Enum.reduce(query, fn equal, acc ->
        key =
          equal
          |> Map.keys()
          |> List.first()

        column = String.to_atom(key)

        acc
        |> where([q], field(q, ^column) == ^equal[key])
      end)
    else
      query
    end
  end

  @doc false
  def set_filter_between(query, filter) do
    if PagingUtil.is_valid_check_filter_between?(filter) do
      filter["between"]
      |> Enum.reduce(query, fn between, acc ->
        key =
          between
          |> Map.keys()
          |> List.first()

        acc
        |> PagingUtil.set_filter_between_conditions(String.to_atom(key), Map.get(between, key))
      end)
    else
      query
    end
  end

  @doc false
  def set_filter_like(query, filter) do
    if PagingUtil.is_valid_check_filter_like?(filter) do
      filter["like"]
      |> Enum.reduce(query, fn equal, acc ->
        key =
          equal
          |> Map.keys()
          |> List.first()

        column = String.to_atom(key)

        acc
        |> where([q], like(field(q, ^column), ^"%#{equal[key]}%"))
      end)
    else
      query
    end
  end

  @doc false
  def set_filter_between_conditions(query, column, between_condition) do
    cond do
      StringUtil.is_empty(between_condition) ->
        query

      !Map.has_key?(between_condition, "from") && !Map.has_key?(between_condition, "to") ->
        query

      Map.has_key?(between_condition, "from") && Map.has_key?(between_condition, "to") ->
        query
        |> where([q], field(q, ^column) >= ^between_condition["from"])
        |> where([q], field(q, ^column) <= ^between_condition["to"])

      Map.has_key?(between_condition, "from") ->
        query
        |> where([q], field(q, ^column) >= ^between_condition["from"])

      Map.has_key?(between_condition, "to") ->
        query
        |> where([q], field(q, ^column) <= ^between_condition["to"])
    end
  end

  @doc false
  def is_valid_check_filter_equal?(filter) do
    cond do
      StringUtil.is_empty(filter) -> false
      StringUtil.is_empty(filter["equal"]) -> false
      true -> true
    end
  end

  @doc false
  def is_valid_check_filter_like?(filter) do
    cond do
      StringUtil.is_empty(filter) -> false
      StringUtil.is_empty(filter["like"]) -> false
      true -> true
    end
  end

  @doc false
  def is_valid_check_filter_between?(filter) do
    cond do
      StringUtil.is_empty(filter) -> false
      StringUtil.is_empty(filter["between"]) -> false
      true -> true
    end
  end

  @doc false
  def is_valid_check_sorter_params?(order) do
    cond do
      StringUtil.is_empty(order) -> false
      StringUtil.is_empty(order["column"]) -> false
      StringUtil.is_empty(order["sorter"]) -> false
      true -> true
    end
  end

  @doc false
  def is_valid_check_offset_params?(paging) do
    cond do
      !PagingUtil.is_valid_check_offset_limit_params?(paging) -> false
      !PagingUtil.is_valid_check_offset_page_params?(paging) -> false
      true -> true
    end
  end

  @doc false
  def is_valid_check_offset_limit_params?(paging) do
    cond do
      StringUtil.is_empty(paging) -> false
      StringUtil.is_empty(paging["limit"]) -> false
      !is_integer(paging["limit"]) -> false
      !Decimal.positive?(Decimal.new(paging["limit"])) -> false
      true -> true
    end
  end

  @doc false
  def is_valid_check_offset_page_params?(paging) do
    cond do
      StringUtil.is_empty(paging) -> false
      StringUtil.is_empty(paging["page"]) -> false
      !is_integer(paging["page"]) -> false
      !Decimal.positive?(Decimal.new(paging["page"])) -> false
      true -> true
    end
  end

  @doc false
  def get_all_result_count(all_result_count, paging) do
    if all_result_count == 0 do
      0
    else
      if PagingUtil.is_valid_check_offset_limit_params?(paging) do
        all_result_count
        |> Decimal.div(paging["limit"])
        |> Decimal.round(0, :up)
        |> Decimal.to_integer()
      else
        1
      end
    end
  end

  @doc false
  def get_current_page_no(paging) do
    if PagingUtil.is_valid_check_offset_page_params?(paging) do
      paging["page"]
    else
      1
    end
  end
end
