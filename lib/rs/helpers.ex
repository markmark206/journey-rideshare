defmodule RS.Helpers do
  @moduledoc false

  @digits "1234567890"
  @letters "ABDEGHJLMRTVXYZ"

  def random_string(prefix \\ "", length \\ 12)
      when is_number(length) and is_binary(prefix) do
    prefix <> Nanoid.generate(length, @digits <> @letters)
  end

  def random_email(prefix \\ "", domain \\ "@example.com") do
    (random_string(prefix) <> domain) |> String.downcase()
  end
end
