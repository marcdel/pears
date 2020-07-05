defmodule Pears.Core.Track do
  defstruct name: nil

  def new(fields) do
    struct!(__MODULE__, fields)
  end
end
