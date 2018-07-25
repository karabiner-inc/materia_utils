defmodule AppExUtils.Calendar.CalendarUtil do
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

end
