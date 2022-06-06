defmodule Game.Maps do
  alias Game.Maps.Map, as: GameMap

  @valid_directions [:up, :down, :left, :right]

  maps_file = Application.app_dir(:game, "priv/static/assets/maps.json")
  @external_resource maps_file

  maps =
    maps_file
    |> File.read!()
    |> Jason.decode!()

  @maps_by_name Map.new(maps, fn map ->
                  [x, y] = map["dimensions"]
                  bricks = MapSet.new(map["bricks"], fn [x, y] -> {x, y} end)

                  map = %GameMap{
                    name: map["name"],
                    dimensions: {x, y},
                    bricks: bricks
                  }

                  {map.name, map}
                end)

  defguard is_valid_direction(direction) when direction in @valid_directions

  def walkable_tile?(map_name, {_x, _y} = position) when is_binary(map_name) do
    case fetch_map(map_name) do
      {:ok, map} -> walkable_tile?(map, position)
      error -> error
    end
  end

  def walkable_tile?(%GameMap{} = map, {_x, _y} = position) do
    inside_borders?(map, position) and not is_brick?(map, position)
  end

  def get_random_map_walkable_tile(map_name) when is_binary(map_name) do
    case fetch_map(map_name) do
      {:ok, map} -> get_random_map_walkable_tile(map)
      error -> error
    end
  end

  def get_random_map_walkable_tile(%GameMap{dimensions: {x, y}} = map) do
    position = {Enum.random(0..x), Enum.random(0..y)}

    if walkable_tile?(map, position), do: position, else: get_random_map_walkable_tile(map)
  end

  def get_random_map_name do
    {map_name, _map} = Enum.random(@maps_by_name)

    map_name
  end

  def fetch_map(map_name) do
    case Map.fetch(@maps_by_name, map_name) do
      {:ok, map} -> {:ok, map}
      :error -> {:error, :not_found}
    end
  end

  def build_matrix(%GameMap{dimensions: {dx, dy}}) do
    for y <- dy..1 do
      for x <- 1..dx do
        {x, y}
      end
    end
  end

  def list_surroundings(map_or_map_name, {_x, _y} = position) do
    @valid_directions
    |> Enum.map(&build_new_position(position, &1))
    |> Enum.filter(&walkable_tile?(map_or_map_name, &1))
  end

  def handle_new_position(map_or_map_name, {_x, _y} = position, direction)
      when is_valid_direction(direction) do
    new_position = build_new_position(position, direction)

    if walkable_tile?(map_or_map_name, new_position), do: new_position, else: position
  end

  defp build_new_position({x, y}, :up), do: {x, y + 1}
  defp build_new_position({x, y}, :down), do: {x, y - 1}
  defp build_new_position({x, y}, :left), do: {x - 1, y}
  defp build_new_position({x, y}, :right), do: {x + 1, y}

  def is_brick?(%GameMap{bricks: bricks}, position), do: MapSet.member?(bricks, position)

  defp inside_borders?(%GameMap{dimensions: {dx, dy}}, {px, py})
       when px > 0 and px <= dx and py > 0 and py <= dy,
       do: true

  defp inside_borders?(_map, _position), do: false
end
