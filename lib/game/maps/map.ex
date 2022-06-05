defmodule Game.Maps.Map do
  fields = [:name, :dimensions, :bricks]

  @enforce_keys fields
  defstruct fields

  @type t :: %__MODULE__{
          name: String.t(),
          dimensions: {non_neg_integer(), non_neg_integer()},
          bricks: MapSet.t()
        }
end
