defmodule AppExUtils.Perser.TsvPerser do

  def parse_tsv_to_json(tsv, header_key) do
    rows = tsv
    |> String.split("\n")
    |> Enum.reject(fn(row) ->
      Regex.match?(~r/^\s*$/,row)
    end)

    #IO.puts("rows:#{inspect(rows)}")

    tables = rows
    |> Enum.map(fn(row) ->
      row
      |> String.split("\t")
    end)

    #IO.puts("tables:#{inspect(tables)}")

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
        #IO.puts("column:#{inspect(column)}")
        cond do
          Regex.match?(~r/NULL/, column) ->
            #IO.puts("match nil !")
            nil
          true ->
            column
        end
      end)
      map = Enum.zip(header, data_row)
      |> Enum.into(%{})
      #IO.puts("map:#{inspect(map)}")
      map
    end)
  end
end

