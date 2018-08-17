defmodule AppExUtils.Perser.TsvPerser do

  def parse_tsv_to_json(tsv, header_key) do
    rows = tsv
    |> String.split("\n")
    |> Enum.reject(fn(row) ->
      Regex.match?(~r/^\s*$/,row)
    end)

    tables = rows
    |> Enum.map(fn(row) ->
      row
      |> String.split("\t")
    end)

    [{header, header_index}] = tables
    |> Enum.with_index()
    |> Enum.filter(fn(with_index) ->
      {columns, index} = with_index
      columns
      |> Enum.any?(fn(column) ->
        column == header_key
      end)
    end)

    data_rows = tables
    |> Enum.slice(header_index + 1,length(tables))

    maps = data_rows
    |> Enum.map(fn(data_row) ->
      data_row = data_row
      |> Enum.map(fn(column) ->
        cond do
          Regex.match?(~r/[NULL]/, column) ->
            nil
          true ->
            column
        end
      end)
      Enum.zip(header, data_row)
      |> Enum.into(%{})
    end)
  end
end

