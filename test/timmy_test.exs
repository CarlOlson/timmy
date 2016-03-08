defmodule TimmyTest do
  use ExUnit.Case
  doctest Timmy

  test "parses lambda terms" do
    assert Timmy.parse "(\\x.x)y[A] : A"
  end
  
  test "global type error" do
    terms = [
      "(\\x.y)y[B] : A",
      "(\\x.zy[B])y[C] : A",
      "(\\x.y)(zy[B])[B] : A",
      "(\\x.y)(\\x.y)[A -> B] : C" ]
    for term <- terms,
    do: assert_raise(Timmy.TypeError, ~r/^global var/,
      fn -> Timmy.parse term end)
  end

  test "bound type error" do
    assert_raise(Timmy.TypeError, ~r/^bound var/,
      fn -> Timmy.parse "(\\x.x) : A -> B" end)
  end

  test "function type error" do
    assert_raise(Timmy.TypeError, ~r/^bad function type/,
      fn -> Timmy.parse "(\\x.x) : A" end)
  end

  test "print" do
    expected_output = 
      "(λx.yx)z : A\n" <>
      "  λx.yx : B -> A\n" <>
      "    yx : A\n" <>
      "      y : B -> A\n" <>
      "      x : B\n" <>
      "  z : B\n"
    ast = Timmy.parse "(\\x.yx[B])z[B] : A"
    {:ok, pid} = StringIO.open("")
    Timmy.print_types ast, pid
    {_input, output} = StringIO.contents pid
    assert output == expected_output
  end
end
