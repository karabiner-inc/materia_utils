defmodule MateriaUtils.Calendar.CalendarUtil do
  alias alias Timex.Timezone
  @moduledoc """
  カレンダー関連のユーティリティー実装

  ベース実装は[timex](https://hex.pm/packages/timex)を使用する

  ロケーションを以下のConfigで設定する。
  ```
   config :materia_utils, calender_locale: "Asia/Tokyo"
   ```
   設定しない場合、サーバーロケールが使用される.。
  """

  @time_zone_utc "Etc/UTC"

  @doc """
  翌日を取得する。

  ```
  iex(1)> Application.put_env(:materia_utils, :calender_locale, "Asia/Tokyo")
  iex(2)> {:ok, datetime} = Timex.parse("2018-08-08T09:00:00Z", "{ISO:Extended:Z}")
  iex(3)> MateriaUtils.Calendar.CalendarUtil.next_date(datetime)
  #DateTime<2018-08-09 09:00:00Z>
  ```

  """
  def next_date(date) do
    Timex.shift(date, days: 1)
  end

  def today() do
    Timex.today()
  end

  @doc """
  サーバーの現在時刻をサーバーに設定されたロケールで取得する

  ```
  # iex(1)> MateriaUtils.Calendar.CalendarUtil.now()
  # #DateTime<2018-11-22 08:44:22.437929Z>
  ```

  """
  def now() do
    Timex.now()
  end

  @doc false
  def convert_time_utc2local(nil) do
    # Timexはnilを渡すとハングするのでスルーさせる
    nil
  end

  @doc """
  utc_datetimeをlocal_datetimeへ変換する

  ```
  iex(1)> Application.put_env(:materia_utils, :calender_locale, "Asia/Tokyo")
  iex(2)> {:ok, utc_datetime} = Timex.parse("2018-08-08T09:00:00Z", "{ISO:Extended:Z}")
  iex(3)> local_datetime = MateriaUtils.Calendar.CalendarUtil.convert_time_utc2local(utc_datetime)
  #DateTime<2018-08-08 18:00:00+09:00 JST Asia/Tokyo>
  ```

  """
  def convert_time_utc2local(datetime) do
    local_time_zone = get_local_time_zone_info()
    Timezone.convert(datetime, local_time_zone)
  end

  @doc false
  def convert_time_local2utc(nil) do
    # Timexはnilを渡すとハングするのでスルーさせる
    nil
  end

  @doc """
  local_datetimeをutc_datetimeへ変換する

  ```
  iex(1)> Application.put_env(:materia_utils, :calender_locale, "Asia/Tokyo")
  iex(2)> {:ok, utc_datetime} = Timex.parse("2018-08-08T09:00:00Z", "{ISO:Extended:Z}")
  iex(3)> local_datetime = MateriaUtils.Calendar.CalendarUtil.convert_time_utc2local(utc_datetime)
  iex(4)> utc_datetime2 = MateriaUtils.Calendar.CalendarUtil.convert_time_local2utc(local_datetime)
  #DateTime<2018-08-08 09:00:00Z>
  ```

  """
  def convert_time_local2utc(datetime) do
    Timezone.convert(datetime, @time_zone_utc)
  end

  @doc false
  def convert_time_string_utc2local(nil) do
    nil
  end

  @doc """
  UTCでの時刻表記文字列(HH:MM:SS)をローカルの時刻表記文字列に変換する

  ```
   iex(1)> Application.put_env(:materia_utils, :calender_locale, "Asia/Tokyo")
   iex(2)> MateriaUtils.Calendar.CalendarUtil.convert_time_string_utc2local("09:00:00")
   "18:00:00"
   ```

  """
  def convert_time_string_utc2local(time_string) do
    with {:ok, datetime} <- Timex.parse("2018-01-02T" <> time_string <> "Z", "{ISO:Extended:Z}") do
      converted_datetime = convert_time_utc2local(datetime)
      Timex.format!(converted_datetime, "%T", :strftime)
    end
  end

  @doc false
  def convert_time_string_local2utc(nil) do
    nil
  end

  @doc """
  ローカルでの時刻表記文字列(HH:MM:SS)をUTCの時刻表記文字列に変換する

  ```
   iex(1)> Application.put_env(:materia_utils, :calender_locale, "Asia/Tokyo")
   iex(2)> MateriaUtils.Calendar.CalendarUtil.convert_time_string_local2utc("18:00:00")
   "09:00:00"
  ```

  """
  def convert_time_string_local2utc(time_string) do
    timezone = get_local_time_zone_info()
    duration = Timex.Duration.from_seconds(timezone.offset_utc())

    with {:ok, datetime} <- Timex.parse("2018-01-02T" <> time_string, "{ISO:Extended:Z}") do
      # 日付固定で変換し、応答日計算後に時刻のみを取りる
      converted_datetime = Timex.subtract(datetime, duration)
      Timex.format!(converted_datetime, "%T", :strftime)
    end
  end

  @doc """
  CalenderUtil用のロケーション設定を取得する

  ```
  iex(1)> Application.put_env(:materia_utils, :calender_locale, "Asia/Tokyo")
  iex(2)> MateriaUtils.Calendar.CalendarUtil.get_local_time_zone_info()
  #<TimezoneInfo(Asia/Tokyo - JST (+09:00:00))>
  ```

  """
  def get_local_time_zone_info() do
    local_timezone_name = Application.get_env(:materia_utils, :calender_locale)

    if local_timezone_name == nil do
      local_time_zone = Timex.Timezone.local()
    else
      local_time_zone = Timex.Timezone.get(local_timezone_name)
    end
  end

  @doc """
  utc_datetimeを元に、ローカルでの一日の開始時刻をutc_date_timeで返す。

  ```
  iex(1)> Application.put_env(:materia_utils, :calender_locale, "Asia/Tokyo")
  iex(2)> {:ok, utc_datetime} = Timex.parse("2018-08-08T09:00:00Z", "{ISO:Extended:Z}")
  iex(3)> MateriaUtils.Calendar.CalendarUtil.get_local_begining_of_day(utc_datetime)
  #DateTime<2018-08-07 15:00:00Z>
  ```

  """
  def get_local_begining_of_day(utc_datetime) do
    local_timezone_name = Application.get_env(:materia_utils, :calender_locale)

    Timex.Timezone.convert(utc_datetime, local_timezone_name)
    |> Timex.beginning_of_day()
    |> Timex.Timezone.convert(@time_zone_utc)
  end

  @doc """
  Enum.max_byでは日付の正しい最大値取得ができない。



  ```
  CalendarUtil.max_by(list, :target_key)
  ```

  """
  def max_by(list, key_atom) do
    if list != nil do
      sorted =
        list
        |> Enum.sort(fn x, y -> Timex.compare(x[key_atom], y[key_atom]) < 0 end)
        |> List.last()
    else
      nil
    end
  end
end
