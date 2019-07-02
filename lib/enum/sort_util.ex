defmodule MateriaUtils.Enum.SortUtil do
  @moduledoc """
  Enum.sort関連のユーティリティー実装
  """

  @doc """
  ソート対象(results)をソート条件のキーワードリスト(keywords)順にソート｡
  iex(1)>  results = []
  iex(2)>  results = [%{id: 1,  string_key: "TEST1", integer_key: 0,   date_key: ~D[2000-03-30], datetime_key: ~N[2018-03-30 00:00:00.000000]}] ++ results
  iex(3)>  results = [%{id: 2,  string_key: "TEST1", integer_key: 0,   date_key: ~D[2000-03-30], datetime_key: ~N[2018-03-31 00:00:00.000000]}] ++ results
  iex(4)>  results = [%{id: 3,  string_key: "TEST1", integer_key: 0,   date_key: ~D[2000-03-30], datetime_key: ~N[2018-04-01 00:00:00.000000]}] ++ results
  iex(5)>  results = [%{id: 4,  string_key: "TEST1", integer_key: 0,   date_key: ~D[2000-03-30], datetime_key: nil                           }] ++ results
  iex(6)>  results = [%{id: 5,  string_key: "TEST1", integer_key: 0,   date_key: ~D[2000-03-31], datetime_key: ~N[2018-03-31 00:00:00.000000]}] ++ results
  iex(7)>  results = [%{id: 6,  string_key: "TEST1", integer_key: 0,   date_key: ~D[2000-04-01], datetime_key: ~N[2018-03-31 00:00:00.000000]}] ++ results
  iex(8)>  results = [%{id: 7,  string_key: "TEST1", integer_key: 0,   date_key: nil,            datetime_key: ~N[2018-03-31 00:00:00.000000]}] ++ results
  iex(9)>  results = [%{id: 8,  string_key: "TEST1", integer_key: 1,   date_key: ~D[2000-03-31], datetime_key: ~N[2018-03-31 00:00:00.000000]}] ++ results
  iex(10)> results = [%{id: 9,  string_key: "TEST1", integer_key: 1.1, date_key: ~D[2000-03-31], datetime_key: ~N[2018-03-31 00:00:00.000000]}] ++ results
  iex(11)> results = [%{id: 10, string_key: "TEST1", integer_key: nil, date_key: ~D[2000-03-31], datetime_key: ~N[2018-03-31 00:00:00.000000]}] ++ results
  iex(12)> results = [%{id: 11, string_key: "TEST2", integer_key: 1,   date_key: ~D[2000-03-31], datetime_key: ~N[2018-03-31 00:00:00.000000]}] ++ results
  iex(13)> results = [%{id: 12, string_key: "",      integer_key: 1,   date_key: ~D[2000-03-31], datetime_key: ~N[2018-03-31 00:00:00.000000]}] ++ results
  iex(14)> results = [%{id: 13, string_key: nil,     integer_key: 1,   date_key: ~D[2000-03-31], datetime_key: ~N[2018-03-31 00:00:00.000000]}] ++ results
  iex(15)> keywords = [{:string_key, :desc}, {:integer_key, :asc}, {:date_key, :desc}, {:datetime_key, :asc}]
  iex(16)> MateriaUtils.Enum.SortUtil.sort_by_keywords(results, keywords)
  [
    %{date_key: ~D[2000-03-31],datetime_key: ~N[2018-03-31 00:00:00.000000],id: 11,integer_key: 1  ,string_key: "TEST2"},
    %{date_key: ~D[2000-03-31],datetime_key: ~N[2018-03-31 00:00:00.000000],id: 10,integer_key: nil,string_key: "TEST1"},
    %{date_key: ~D[2000-04-01],datetime_key: ~N[2018-03-31 00:00:00.000000],id: 6 ,integer_key: 0  ,string_key: "TEST1"},
    %{date_key: ~D[2000-03-31],datetime_key: ~N[2018-03-31 00:00:00.000000],id: 5 ,integer_key: 0  ,string_key: "TEST1"},
    %{date_key: ~D[2000-03-30],datetime_key: nil                           ,id: 4 ,integer_key: 0  ,string_key: "TEST1"},
    %{date_key: ~D[2000-03-30],datetime_key: ~N[2018-03-30 00:00:00.000000],id: 1 ,integer_key: 0  ,string_key: "TEST1"},
    %{date_key: ~D[2000-03-30],datetime_key: ~N[2018-03-31 00:00:00.000000],id: 2 ,integer_key: 0  ,string_key: "TEST1"},
    %{date_key: ~D[2000-03-30],datetime_key: ~N[2018-04-01 00:00:00.000000],id: 3 ,integer_key: 0  ,string_key: "TEST1"},
    %{date_key: nil           ,datetime_key: ~N[2018-03-31 00:00:00.000000],id: 7 ,integer_key: 0  ,string_key: "TEST1"},
    %{date_key: ~D[2000-03-31],datetime_key: ~N[2018-03-31 00:00:00.000000],id: 8 ,integer_key: 1  ,string_key: "TEST1"},
    %{date_key: ~D[2000-03-31],datetime_key: ~N[2018-03-31 00:00:00.000000],id: 9 ,integer_key: 1.1,string_key: "TEST1"},
    %{date_key: ~D[2000-03-31],datetime_key: ~N[2018-03-31 00:00:00.000000],id: 12,integer_key: 1  ,string_key: ""},
    %{date_key: ~D[2000-03-31],datetime_key: ~N[2018-03-31 00:00:00.000000],id: 13,integer_key: 1  ,string_key: nil}
  ]
  iex(15)> keywords = [{:datetime_key, :asc}]
  iex(16)> MateriaUtils.Enum.SortUtil.sort_by_keywords(results, keywords)
  [
    %{date_key: ~D[2000-03-30],datetime_key: nil                           ,id: 4 ,integer_key: 0  ,string_key: "TEST1"},
    %{date_key: ~D[2000-03-30],datetime_key: ~N[2018-03-30 00:00:00.000000],id: 1 ,integer_key: 0  ,string_key: "TEST1"},
    %{date_key: ~D[2000-03-30],datetime_key: ~N[2018-03-31 00:00:00.000000],id: 2 ,integer_key: 0  ,string_key: "TEST1"},
    %{date_key: ~D[2000-03-31],datetime_key: ~N[2018-03-31 00:00:00.000000],id: 5 ,integer_key: 0  ,string_key: "TEST1"},
    %{date_key: ~D[2000-04-01],datetime_key: ~N[2018-03-31 00:00:00.000000],id: 6 ,integer_key: 0  ,string_key: "TEST1"},
    %{date_key: nil           ,datetime_key: ~N[2018-03-31 00:00:00.000000],id: 7 ,integer_key: 0  ,string_key: "TEST1"},
    %{date_key: ~D[2000-03-31],datetime_key: ~N[2018-03-31 00:00:00.000000],id: 8 ,integer_key: 1  ,string_key: "TEST1"},
    %{date_key: ~D[2000-03-31],datetime_key: ~N[2018-03-31 00:00:00.000000],id: 9 ,integer_key: 1.1,string_key: "TEST1"},
    %{date_key: ~D[2000-03-31],datetime_key: ~N[2018-03-31 00:00:00.000000],id: 10,integer_key: nil,string_key: "TEST1"},
    %{date_key: ~D[2000-03-31],datetime_key: ~N[2018-03-31 00:00:00.000000],id: 11,integer_key: 1  ,string_key: "TEST2"},
    %{date_key: ~D[2000-03-31],datetime_key: ~N[2018-03-31 00:00:00.000000],id: 12,integer_key: 1  ,string_key: ""},
    %{date_key: ~D[2000-03-31],datetime_key: ~N[2018-03-31 00:00:00.000000],id: 13,integer_key: 1  ,string_key: nil},
    %{date_key: ~D[2000-03-30],datetime_key: ~N[2018-04-01 00:00:00.000000],id: 3 ,integer_key: 0  ,string_key: "TEST1"}
  ]
  """
  def sort_by_keywords(results, keywords) do
    results
    |> Enum.sort(
         fn current, next ->
           current = Map.delete(current, :__struct__)
           next = Map.delete(next, :__struct__)
           is_sorted = keywords
                       |> Enum.reduce(
                            nil,
                            fn keyword, acc ->
                              _ = cond do
                                is_nil(acc) ->
                                  {key, sorter} = keyword
                                  compare(current[key], next[key], sorter)
                                true -> acc
                              end
                            end
                          )
           _ = cond do
             is_nil(is_sorted) -> false
             true -> is_sorted
           end
         end
       )
  end

  @doc """
  Timex.is_valid?が成立しない場合 -> 単純な評価を行う｡ ※ Nil Firstとして扱う(数値とNilの比較時は逆になってしまうので合わせる)
  Timex.is_valid?が成立する場合(Date型,DateTime型) -> Timex.compareで判定する｡

  iex(1)> MateriaUtils.Enum.SortUtil.compare("TEST1", "TEST2", :asc)
  true
  iex(2)> MateriaUtils.Enum.SortUtil.compare(~D[2000-03-31], ~D[2000-04-01], :asc)
  true
  iex(3)> MateriaUtils.Enum.SortUtil.compare(~N[2018-03-31 00:00:00.000000], ~N[2018-04-01 00:00:00.000000], :asc)
  true
  iex(4)> MateriaUtils.Enum.SortUtil.compare(1.0, 1.01, :asc)
  true
  ## 降順
  iex(1)> MateriaUtils.Enum.SortUtil.compare("TEST1", "TEST2", :desc)
  false
  iex(2)> MateriaUtils.Enum.SortUtil.compare(~D[2000-03-31], ~D[2000-04-01], :desc)
  false
  iex(3)> MateriaUtils.Enum.SortUtil.compare(~N[2018-03-31 00:00:00.000000], ~N[2018-04-01 00:00:00.000000], :desc)
  false
  iex(4)> MateriaUtils.Enum.SortUtil.compare(1.0, 1.01, :desc)
  false
  ## 同値
  iex(1)> MateriaUtils.Enum.SortUtil.compare("TEST1", "TEST1", :asc)
  nil
  iex(2)> MateriaUtils.Enum.SortUtil.compare(1, 1.0, :asc)
  nil
  ## nilを含む
  iex(1)> MateriaUtils.Enum.SortUtil.compare(nil, nil, :asc)
  nil
  iex(2)> MateriaUtils.Enum.SortUtil.compare("TEST1", nil, :asc)
  false
  iex(3)> MateriaUtils.Enum.SortUtil.compare(~D[2000-03-31], nil, :asc)
  false
  iex(4)> MateriaUtils.Enum.SortUtil.compare(~N[2018-03-31 00:00:00.000000], nil, :asc)
  false
  iex(5)> MateriaUtils.Enum.SortUtil.compare(1, nil, :asc)
  false

  """
  def compare(current, next, sorter) do
    _ = cond do
      Timex.is_valid?(current) and Timex.is_valid?(next) ->
        _ = cond do
          Timex.compare(current, next) < 0 -> !(sorter == :desc)
          Timex.compare(current, next) > 0 -> (sorter == :desc)
          true -> nil
        end
      is_nil(current) and is_nil(next) -> nil
      is_nil(current) -> !(sorter == :desc)
      is_nil(next) -> (sorter == :desc)
      current < next -> !(sorter == :desc)
      current > next -> (sorter == :desc)
      true -> nil
    end
  end
end
