defmodule AppEx.TsvPerser do

  alias AppEx.Orders
  alias AppEx.Accounts.User

  @create_order_001_attrs  "
  id	car_id	user_id	chap	hollow	curve	disassemble	spoiler	metal_shape	damage_shape	damage_degree	area_x	area_y	paint_type	paint_completion	material	part	car_size	dismantle	direction_side	exchange	frame_amend_set	inner_flag	inserted_at	updated_at
  21	10	1	[NULL]	[NULL]	[NULL]	[NULL]	[NULL]	[NULL]	[NULL]	[NULL]	0.0000	0.0000	[NULL]	[NULL]	[NULL]	センターピラー	[NULL]	[NULL]	右側面	[NULL]	[NULL]	1	2018-07-17 08:18:24	2018-07-17 08:18:43
  22	10	1	なし	なし	なし	F	F	なし	面状	へこみ５ｍｍ以上	2.0000	1.0000	3CP	T	樹脂	フロントバンパー	普通車	T	前方	[NULL]	[NULL]	0	2018-07-17 08:18:24	2018-07-17 08:18:35
  24	11	1	なし	なし	なし	F	F	なし	面状	へこみ５ｍｍ以上	2.0000	1.0000	2CM/M	T	[NULL]	フロントドア	普通車	T	左側面	[NULL]	[NULL]	0	2018-07-17 08:21:54	2018-07-17 08:22:21
  23	11	1	なし	なし	なし	F	F	なし	面状	へこみ５ｍｍ以上	1.0000	2.0000	2CM/M	T	[NULL]	フェンダー	普通車	T	前方	[NULL]	[NULL]	0	2018-07-17 08:21:54	2018-07-17 08:22:13
  25	12	1	なし	なし	なし	F	F	なし	面状	へこみ５ｍｍ以上	1.0000	1.0000	2CM/M	T	[NULL]	フロントドア	普通車	T	左側面	[NULL]	[NULL]	0	2018-07-17 09:09:54	2018-07-17 09:10:11
  26	12	1	なし	なし	なし	F	F	なし	線状	[NULL]	2.0000	10.0000	2CM/M	T	[NULL]	フロントエンドパネル	普通車	T	前方	[NULL]	[NULL]	0	2018-07-17 09:09:54	2018-07-17 09:10:01
  28	13	1	なし	なし	なし	F	F	なし	線状	[NULL]	2.0000	10.0000	3CP	T	[NULL]	フロントエンドパネル	軽自動車	T	前方	[NULL]	[NULL]	0	2018-07-17 09:20:26	2018-07-17 09:20:47
  27	13	1	なし	なし	なし	F	F	なし	面状	へこみ５ｍｍ以上	1.0000	2.0000	3CP	T	樹脂	サイドスポイラー	軽自動車	T	右側面	[NULL]	[NULL]	0	2018-07-17 09:20:26	2018-07-17 09:20:38
  29	14	1	[NULL]	[NULL]	[NULL]	[NULL]	[NULL]	[NULL]	[NULL]	[NULL]	0.0000	0.0000	[NULL]	[NULL]	[NULL]	ルーフサイドパネル	[NULL]	[NULL]	右側面	[NULL]	[NULL]	1	2018-07-17 09:21:49	2018-07-17 09:22:05
  30	14	1	なし	なし	なし	F	F	なし	面状	へこみ５ｍｍ以上	3.0000	1.0000	3CP	T	樹脂	サイドスポイラー	大型車	T	右側面	[NULL]	[NULL]	0	2018-07-17 09:21:49	2018-07-17 09:21:59
      "

  # sample function
  def create_order_paramaters() do

    jsons = parse_tsv_to_json(@create_order_001_attrs)
    jsons
    |> Enum.each(fn(json) ->
      {:ok, order_paramater} = json
      |> Orders.create_order_paramater([user: %User{id: 1}, space: "karabiner"])
    end)

  end

  def parse_tsv_to_json(tsv) do
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
        column == "inserted_at"
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

