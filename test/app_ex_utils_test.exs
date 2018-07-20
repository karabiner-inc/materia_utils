defmodule AppExUtilsTest do
  use ExUnit.Case
  doctest AppExUtils

  test "greets the world" do
    assert AppExUtils.hello() == :world
  end
end
