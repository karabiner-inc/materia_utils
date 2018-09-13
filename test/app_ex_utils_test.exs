defmodule ServicexUtilsTest do
  use ExUnit.Case
  doctest ServicexUtils

  test "greets the world" do
    assert ServicexUtils.hello() == :world
  end
end
