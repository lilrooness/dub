defmodule TestyTest do
  use ExUnit.Case

  use Dub, [Testy]

  # doctest Testy

  describe "Testy" do
    setup do
      Testy
      |> expect(:hello, fn -> :world end, 1)

      :ok
    end

    test "greets the world" do
      assert Testy.hello() == :world
    end
  end
end
