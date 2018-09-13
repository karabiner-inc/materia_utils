defmodule ServicexUtils.Calendar.CalendarUtil do
  @moduledoc """
  日付関連の操作機能
  """

  alias  alias Timex.Timezone

  @time_zone_utc "Etc/UTC"

  def next_date(date) do
    Timex.shift(date, days: 1)
  end

  def today() do
    Timex.today
  end

  def now() do
    Timex.now
  end

  def ecto_datetime_now() do
    {:ok, now_datetime } = now()
    |> convert_time_utc2local()
    |> Timex.format!("%FT%T", :strftime)
    |> Ecto.DateTime.cast()
    now_datetime
  end

  def convert_time_utc2local(nil) do
    #Timexはnilを渡すとハングするのでスルーさせる
    nil
  end
  def convert_time_utc2local(datetime) do
    local_time_zone = Timezone.Local.lookup()
    Timezone.convert(datetime,local_time_zone)
  end

  def convert_time_local2utc(nil) do
    #Timexはnilを渡すとハングするのでスルーさせる
    nil
  end
  def convert_time_local2utc(datetime) do
    Timezone.convert(datetime,@time_zone_utc)
  end

  def perse_datetime_strftime(attr, key_list) when is_map(attr) and is_list(key_list) do
    converted_attr = key_list
    |> Enum.reduce(attr, fn(key, attr) ->
        attr =
        if Map.has_key?(attr, key) and attr[key] != nil do
          {:ok, date_time} = Timex.parse(attr[key],"%Y-%m-%d %H:%M:%S%:z", :strftime)
          Map.put(attr, key, date_time)
        else
          attr
        end
    end)
    converted_attr
  end

  def convert_time_local2utc(attr, key_list) when is_map(attr) and is_list(key_list) do
    converted_attr = key_list
    |> Enum.reduce(attr, fn(key, attr) ->
        attr =
        if Map.has_key?(attr, key) and attr[key] != nil do
          Map.put(attr, key, Timex.Timezone.convert(attr[key], "Etc/UTC"))
        else
          attr
        end
    end)
    converted_attr
  end

end
