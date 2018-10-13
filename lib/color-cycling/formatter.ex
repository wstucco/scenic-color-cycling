defmodule ColorCycling.TimeFormatter do
  @minute 60
  @millisecond 1_000

  def format(duration) when is_number(duration) do
    format({div(duration, @millisecond), rem(duration, @millisecond)})
  end

  def format({0, microseconds}) do
    "#{microseconds} µs"
  end

  def format({milliseconds, _}) when milliseconds < @millisecond do
    "#{milliseconds} ms"
  end

  def format({milliseconds, _}) do
    format(div(milliseconds, @millisecond), :second)
  end

  def format(seconds, :second) when seconds < @minute do
    "#{seconds} seconds"
  end

  def format(seconds, :second) do
    format({div(seconds, @minute), rem(seconds, @minute)}, :minute)
  end

  def format({minutes, seconds}, :minute) when minutes < @minute do
    "#{minutes} minutes #{seconds} seconds"
  end

  def format({minutes, seconds}, :minute) do
    format({div(minutes, @minute), rem(minutes, @minute), seconds}, :hour)
  end

  def format({hours, minutes, seconds}, :hour) do
    "#{hours} hours #{minutes} minutes #{seconds} seconds"
  end
end
