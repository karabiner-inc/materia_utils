defmodule MateriaUtils.Calendar.CalendarUtil do
  alias alias Timex.Timezone

  @moduledoc """
  カレンダー関連のユーティリティー実装

  ベース実装は[timex](https://hex.pm/packages/timex)を使用する

  ロケーションを以下のConfigで設定する。
  ```
   config :materia_utils, calender_locale: "Asia/Tokyo"
   ```
   設定しない場合、サーバーロケールが使用される。

   また、テスト基準日時を設定した場合、サーバー時刻ではなく、設定した固定時刻を現在時刻として返す。
   config :materia_utils, test_base_datetime: "2019-01-01T00:00:00.000Z"
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
  @spec next_date(DateTime) :: DateTime
  def next_date(date) do
    Timex.shift(date, days: 1)
  end

  @doc """
  本日を取得する。

  ```
  iex(1)> Application.put_env(:materia_utils, :test_base_datetime, "2019-01-01T00:00:00.000Z")
  iex(2)> MateriaUtils.Calendar.CalendarUtil.today()
  ~D[2019-01-01]
  ```

  """
  @spec today() :: Date
  def today() do
    test_base_datetime = Application.get_env(:materia_utils, :test_base_datetime)

    if test_base_datetime == nil do
      Timex.today()
    else
      {:ok, base_datetime} = Timex.parse(test_base_datetime, "{ISO:Extended}")
      DateTime.to_date(base_datetime)
    end
  end

  @doc """
  サーバーの現在時刻をサーバーに設定されたロケールで取得する


  ```
  iex(1)> Application.put_env(:materia_utils, :test_base_datetime, "2019-01-01T00:00:00.000Z")
  iex(2)> MateriaUtils.Calendar.CalendarUtil.now()
  #DateTime<2019-01-01 00:00:00.000Z>
  ```

  """
  @spec now() :: DateTime
  def now() do
    test_base_datetime = Application.get_env(:materia_utils, :test_base_datetime)

    if test_base_datetime == nil do
      Timex.now()
    else
      {:ok, base_datetime} = Timex.parse(test_base_datetime, "{ISO:Extended}")
      base_datetime
    end

  end

  @doc """
  現在時刻をEcto.DateTime型で返す

  """
  @spec ecto_datetime_now() :: Ecto.DateTime
  def ecto_datetime_now() do
    {:ok, now_datetime } = now()
    |> convert_time_utc2local()
    |> Timex.format!("%FT%T", :strftime)
    |> Ecto.DateTime.cast()
    now_datetime
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
  @spec convert_time_utc2local(DateTime) :: DateTime
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
  @spec convert_time_local2utc(DateTime) :: DateTime
  def convert_time_local2utc(datetime) do
    Timezone.convert(datetime, @time_zone_utc)
  end

  @doc """
  local_datetimeをutc_datetimeへ変換する

  ```
  iex(1)> Application.put_env(:materia_utils, :calender_locale, "Asia/Tokyo")
  iex(2)> {:ok, utc_datetime} = Timex.parse("2018-08-08T09:00:00Z", "{ISO:Extended:Z}")
  iex(3)> local_datetime = MateriaUtils.Calendar.CalendarUtil.convert_time_utc2local(utc_datetime)
  iex(4)> utc_datetime2 = MateriaUtils.Calendar.CalendarUtil.convert_time_local2utc(%{start_date: local_datetime}, [:start_date])
  iex(5)> utc_datetime2.start_date
  #DateTime<2018-08-08 09:00:00Z>
  ```

  """
  @spec convert_time_local2utc(Map, List) :: Map
  def convert_time_local2utc(attr, key_list) when is_map(attr) and is_list(key_list) do
    converted_attr = key_list
    |> Enum.reduce(attr, fn(key, attr) ->
        value = Map.get(attr, key)
        attr =
        if Map.has_key?(attr, key) and value != nil do
          Map.put(attr, key, Timex.Timezone.convert(value, "Etc/UTC"))
        else
          attr
        end
    end)
    converted_attr
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
  @spec convert_time_string_utc2local(String) :: String
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
  @spec convert_time_string_utc2local(String) :: String
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
  # iex(1)> Application.put_env(:materia_utils, :calender_locale, "Asia/Tokyo")
  # iex(2)> MateriaUtils.Calendar.CalendarUtil.get_local_time_zone_info()
  # #<TimezoneInfo(Asia/Tokyo - JST (+09:00:00))>
  ```

  """
  @spec get_local_time_zone_info() :: Timex.Timezone
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
  @spec get_local_begining_of_day(DateTime) :: DateTime
  def get_local_begining_of_day(utc_datetime) do
    local_timezone_name = Application.get_env(:materia_utils, :calender_locale)

    Timex.Timezone.convert(utc_datetime, local_timezone_name)
    |> Timex.beginning_of_day()
    |> Timex.Timezone.convert(@time_zone_utc)
  end

  @doc """
  Enum.max_byでは日付の正しい最大値取得ができない。
  Timex.Datetimeのmax取得はこの関数の使用を推奨

  ```
  defp timex_parser(time_string) do
    {:ok, datetime} = Timex.parse(time_string, "{ISO:Extended:Z}")
    datetime
  end

  〜中略〜

  list = [
        %{check_time: timex_parser("2018-11-21 00:00:01Z")},
        %{check_time: timex_parser("2018-11-21 00:00:00Z")},
        %{check_time: timex_parser("2018-11-21 00:00:03Z")},
      ]

  max_map = %{check_time: timex_parser("2018-11-21 00:00:03Z")}

  result_map = CalendarUtil.max_by(list, :check_time)
  assert result_map == max_map
  ```

  """
  @spec max_by([list], atom) :: DateTime
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

  @doc """
  ISO拡張文字列表記の時刻をDateTime型にパースする

  ### Example

  ```
  iex(1)> {:ok, datetime } = MateriaUtils.Calendar.CalendarUtil.parse_iso_extended_z("2018-08-08 09:00:00Z")
  iex(2)> datetime
  #DateTime<2018-08-08 09:00:00Z>
  ```

  """
  @spec parse_iso_extended_z(String) :: DateTime
  def parse_iso_extended_z(datetime_string) do
    Timex.parse(datetime_string, "{ISO:Extended:Z}")
  end

  @doc """
  文字列日時(YYYY-MM-DD hh:mm:ssZ)をISO拡張文字列表記の時刻にパースする

  ### Example

  ```
  iex(1)> datetime_map =  MateriaUtils.Calendar.CalendarUtil.parse_datetime_strftime(%{start_date: "2010-04-17 14:00:00Z", end_date: "2010-04-17 15:00:00Z" }, [:start_date, :end_date])
  iex(2)> datetime_map.start_date
  #DateTime<2010-04-17 14:00:00Z>
  ```

  """
  def parse_datetime_strftime(attr, key_list) when is_map(attr) and is_list(key_list) do
    converted_attr = key_list
    |> Enum.reduce(attr, fn(key, attr) ->
        value = Map.get(attr, key)
        attr =
        if Map.has_key?(attr, key) and value != nil do
          with {:ok, date_time} <- Timex.parse(value, "{ISO:Extended:Z}") do
            Map.put(attr, key, date_time)
          else
            _ -> attr
          end
        else
          attr
        end
    end)
    converted_attr
  end
end
