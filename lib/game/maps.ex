defmodule Game.Maps do
  alias Game.Maps.Map, as: GameMap

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

  def walkable_tile?(map_name, {_x, _y} = tile) when is_binary(map_name) do
    case fetch_map(map_name) do
      {:ok, map} -> walkable_tile?(map, tile)
      error -> error
    end
  end

  def walkable_tile?(%GameMap{} = map, {_x, _y} = tile) do
    inside_borders?(map, tile) and not_a_brick?(map, tile)
  end

  def get_random_valid_map_position(map_name) when is_binary(map_name) do
    case fetch_map(map_name) do
      {:ok, map} -> get_random_valid_map_position(map)
      error -> error
    end
  end

  def get_random_valid_map_position(%GameMap{dimensions: {x, y}} = map) do
    tile = {Enum.random(0..x), Enum.random(0..y)}

    if walkable_tile?(map, tile), do: tile, else: get_random_valid_map_position(map)
  end

  def get_random_map_name do
    {map_name, _map} = Enum.random(@maps_by_name)

    map_name
  end

  defp fetch_map(map_name) do
    case Map.fetch(@maps_by_name, map_name) do
      {:ok, map} -> {:ok, map}
      :error -> {:error, :not_found}
    end
  end

  defp inside_borders?(%GameMap{dimensions: {d_x, d_y}}, {x, y})
       when x >= 0 and x <= d_x and y >= 0 and y <= d_y,
       do: true

  defp inside_borders?(_map, _tile), do: false

  defp not_a_brick?(%GameMap{bricks: bricks}, tile), do: !MapSet.member?(bricks, tile)
end
