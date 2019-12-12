defmodule MateriaUtils.CalendarUtilTest do
  use ExUnit.Case
  doctest MateriaUtils.Calendar.CalendarUtil

  alias MateriaUtils.Calendar.CalendarUtil

  defp timex_parser(time_string) do
    {:ok, datetime} = Timex.parse(time_string, "{ISO:Extended:Z}")
    datetime
  end

  describe "max_by" do
    test "normal case" do
      list = [
        %{check_time: timex_parser("2018-11-21 00:00:01Z")},
        %{check_time: timex_parser("2018-11-21 00:00:00Z")},
        %{check_time: timex_parser("2018-11-21 00:00:03Z")}
      ]

      max_map = %{check_time: timex_parser("2018-11-21 00:00:03Z")}

      result_map = CalendarUtil.max_by(list, :check_time)
      assert result_map == max_map
    end

    test "blank list" do
      list = []

      result_map = CalendarUtil.max_by(list, :check_time)
      assert result_map == nil
    end

    test "nil list" do
      list = nil

      result_map = CalendarUtil.max_by(list, :check_time)
      assert result_map == nil
    end

    test "only one element list" do
      list = [
        %{check_time: timex_parser("2018-11-21 00:00:03Z")}
      ]

      max_map = %{check_time: timex_parser("2018-11-21 00:00:03Z")}

      result_map = CalendarUtil.max_by(list, :check_time)
      assert result_map == max_map
    end
  end
end
