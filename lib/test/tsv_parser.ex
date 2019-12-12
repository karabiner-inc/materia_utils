defmodule MateriaUtils.Test.TsvParser do
  @moduledoc """
   テストおよびseeds用のデータパーサー
   TSVフォーマットのテキストデータをMapに変換し、関数の入力として利用しやすく変換する。



  """

  @doc """
  tsvのテキストデータをMapに変換する。

  "col_int col_string col_date"

  [
    %{
      "col_date" => #DateTime<2018-07-17 08:18:24Z>,
      "col_int" => " 1",
      "col_string" => "aaaa"
    },
    %{
      "col_date" => #DateTime<2018-07-14 08:18:24Z>,
      "col_int" => " 2",
      "col_string" => "bbbb"
    }
  ]

  ```

  　iex(1)> tsv = "col_int\tcol_string\tcol_date
     ...(1)> 1\taaaa\t2018-07-17 08:18:24
     ...(1)> 2\tbbbb\t2018-07-14 08:18:24
     ...(1)> "
     iex(2)> map_list = MateriaUtils.Test.TsvParser.parse_tsv_to_json(tsv, "col_int")
     iex(3)> length(map_list)
     2
  ```

  """
  @spec parse_tsv_to_json(String, String) :: Map
  def parse_tsv_to_json(tsv, header_key) do
    rows =
      tsv
      |> String.split("\n")
      |> Enum.reject(fn row ->
        Regex.match?(~r/^\s*$/, row)
      end)

    tables =
      rows
      |> Enum.map(fn row ->
        row
        |> String.split("\t")
      end)

    [{header, header_index}] =
      tables
      |> Enum.with_index()
      |> Enum.filter(fn with_index ->
        {columns, index} = with_index

        columns
        |> Enum.any?(fn column ->
          column == header_key
        end)
      end)

    data_rows =
      tables
      |> Enum.slice(header_index + 1, length(tables))

    maps =
      data_rows
      |> Enum.map(fn data_row ->
        data_row =
          data_row
          |> Enum.map(fn column ->
            cond do
              Regex.match?(~r/NULL/, column) ->
                nil

              true ->
                # dateitimeにconvert可能であればconvertする
                with {:ok, datetime} <- Timex.parse(column <> "Z", "{ISO:Extended:Z}") do
                  datetime
                else
                  {:error, _reason} ->
                    column
                end
            end
          end)

        map =
          Enum.zip(header, data_row)
          |> Enum.into(%{})

        map
      end)
  end
end
