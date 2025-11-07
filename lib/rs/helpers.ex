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

  def to_datetime_string!(unix_timestamp, time_zone, include_date \\ true)

  def to_datetime_string!(unix_timestamp, nil, include_date) do
    to_datetime_string!(unix_timestamp, "Etc/UTC", include_date)
  end

  def to_datetime_string!(unix_timestamp, time_zone, include_date) do
    unix_timestamp
    |> DateTime.from_unix!()
    |> DateTime.shift_zone!(time_zone)
    |> Calendar.strftime(if include_date, do: "%Y-%m-%d %H:%M:%S", else: "%H:%M:%S")
  end
end
