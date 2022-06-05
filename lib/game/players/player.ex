defmodule Game.Players.Player do
  fields = [:name, :alive?, :map_name, :position]

  @enforce_keys fields
  defstruct fields

  @type t :: %__MODULE__{
          name: String.t(),
          alive?: boolean(),
          map_name: String.t(),
          position: {non_neg_integer(), non_neg_integer()}
        }

  def new(attrs) do
    attrs =
      attrs
      |> Map.new()
      |> Map.put(:alive?, true)

    struct!(__MODULE__, attrs)
  end
end
