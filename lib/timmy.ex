defmodule Timmy do
  @moduledoc """
  Timmy's first type checker using annotated applications.
  """

  require :timmy_lexer
  require :timmy_annotated_app

  defmodule TypeError do
    defexception message: "lambda term typing error"
  end

  defmodule ParseError do
    defexception message: "lambda term parsing error"
  end

  # ~> is syntactic sugar for defining function types.
  defmacrop type1 ~> type2 do
    quote do: {unquote(type1), unquote(type2)}
  end

  @doc """
  Parses and performs type inference on lambda terms.
  
  λ or \\ can be used for a lambda.
  
  ## Examples

      iex> Timmy.parse "(λx.x) : A -> A"
      {:lambda, {'x', 'A'}, {:var, 'x', 'A'}, {'A', 'A'}}
  """
  def parse(code) when is_binary(code) do
    code = code
    |> String.replace("λ", "\\")
    |> String.to_char_list

    ast =
      try do
        {:ok, tokens, _} = :timmy_lexer.string(code)
        {:ok, ast} = :timmy_annotated_app.parse(tokens)
        ast
      rescue
        err in MatchError ->
          %MatchError{term: term} = err
          raise ParseError, inspect term
      end
    typed_ast = type_infer ast

    # Ensure all global vars have matching types.
    for( { var, t1} <- get_globals(typed_ast),
         {^var, t2} <- get_globals(typed_ast),
         t1 != t2,
         do: raise( TypeError, "global var '#{var}' type mismatch, " <>
           "#{type_to_string t1} != #{type_to_string t2}" ))
    
    typed_ast
  end

  defp type_infer({:terms, term, type}) do
    type_infer(term, type, [])
  end

  defp type_infer({:var, var}, type, bound) do
    shadow = Enum.find(bound,
      fn {binding, _} -> binding == var end)

    case shadow do
      {_, unexpected} when unexpected != type ->
        raise( TypeError, "bound var '#{var}' type mismatch, " <>
          "#{type_to_string type} != #{type_to_string unexpected}" )
      _else -> {:var, var, type}
    end
  end
  
  defp type_infer({:lambda, binding, term},
                  binding_type ~> return_type,
                  bound) do
    { :lambda,
      {binding, binding_type},
      type_infer(term, return_type,
                 [{binding, binding_type} | bound]),
      binding_type ~> return_type }
  end

  defp type_infer(term={:lambda, _, _}, type, _) do
    raise( TypeError, "bad function type, " <>
      "#{term_to_string term} : #{type_to_string type}" )
  end

  defp type_infer({:app, term1, term2, term2_type},
                  type, bound) do
    { :app,
      type_infer(term1, term2_type ~> type, bound),
      type_infer(term2, term2_type, bound),
      type }
  end

  @doc """
  Prints lambda terms and their sub-terms with types.
  """
  @indent "  "
  def print_types(terms, device \\ Process.group_leader) do
    print_types(terms, 0, device)
  end

  defp print_types(term={:var, _var, type}, depth, device) do
    IO.write device, String.duplicate(@indent, depth)
    IO.puts device, "#{term_to_string term} : #{type_to_string type}"
  end

  defp print_types(term={:lambda, _binding, body, type}, depth, device) do
    IO.write device, String.duplicate(@indent, depth)
    IO.puts device, "#{term_to_string term} : #{type_to_string type}"
    print_types(body, depth + 1, device)
  end

  defp print_types(term={:app, term1, term2, type}, depth, device) do
    IO.write device, String.duplicate(@indent, depth)
    IO.puts device, "#{term_to_string term} : #{type_to_string type}"
    print_types(term1, depth + 1, device)
    print_types(term2, depth + 1, device)
  end
  
  @doc """
  Returns variables as {name, type} tuples, contains duplicates if
  type was derived more than once. If given improper input, duplicates
  can have type conflicts.

  ## Examples

      iex> Timmy.get_globals Timmy.parse "yx[A] : B"
      [{'y', {'A', 'B'}}, {'x', 'A'}]
  """
  def get_globals(term) do
    get_globals(term, [])
  end

  defp get_globals({:var, var, type}, bound) do
    is_bound = Enum.find(bound, fn {v, _} -> v == var end)
    if is_bound, do: [], else: [{var, type}]
  end

  defp get_globals({:lambda, binding, term, _type}, bound) do
    get_globals(term, [binding | bound])
  end

  defp get_globals({:app, term1, term2, _type}, bound) do
    get_globals(term1, bound) ++ get_globals(term2, bound)
  end

  @doc """
  Converts a lambda term's type into a string with minimum
  parenthesis.

  ## Examples

      iex> Timmy.type_to_string {{'A', {'B', 'C'}}, 'D'}
      "(A -> B -> C) -> D"
  """
  def type_to_string(t1 ~> t2) when is_tuple(t1) do
    "(#{type_to_string t1}) -> #{type_to_string t2}"
  end
  
  def type_to_string(t1 ~> t2) do
    "#{type_to_string t1} -> #{type_to_string t2}"
  end
  
  def type_to_string(type) do
    "#{type}"
  end

  @doc """
  Converts lambda terms into string with minimum parenthesis. Type
  information is optional and ignored.

  ## Examples

      iex> term = "(λx.x)(λx.x)[B -> B] : B -> B"
      iex> Timmy.term_to_string Timmy.parse term
      "(λx.x)λx.x"
  """
  def term_to_string(term) do
    term_to_string(term, :right)
  end
  
  defp term_to_string({:var, var, _type}, _dir) do
    "#{var}"
  end
  
  defp term_to_string({:var, var}, _dir) do
    "#{var}"
  end
  
  defp term_to_string({:lambda, {binding, _btype}, term, _type}, dir) do
    if dir == :left do
      "(λ#{binding}.#{term_to_string term, :right})"
    else
      "λ#{binding}.#{term_to_string term, :right}"
    end
  end
  
  defp term_to_string({:lambda, binding, term}, dir) do
    if dir == :left do
      "(λ#{binding}.#{term_to_string term, :right})"
    else
      "λ#{binding}.#{term_to_string term, :right}"
    end
  end
  
  defp term_to_string({:app, term1, term2, _type}, dir) do
    "#{term_to_string term1, :left}#{term_to_string term2, dir}"
  end
  
  defp term_to_string({:app, term1, term2}, dir) do
    "#{term_to_string term1, :left}#{term_to_string term2, dir}"
  end
  
end
