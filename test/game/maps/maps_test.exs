defmodule Game.MapsTest do
  use ExUnit.Case, async: true

  alias Game.Maps
  alias Game.Maps.Map, as: GameMap

  @map_name "Winterfell"

  describe "fetch_map/1" do
    test "fetches a map by name" do
      assert {:ok, %GameMap{name: @map_name}} = Maps.fetch_map(@map_name)
    end

    test "invalid map name" do
      assert {:error, "map not found"} = Maps.fetch_map("invalid name")
    end
  end

  describe "walkable_tile?/2" do
    test "when tile is walkable" do
      assert Maps.walkable_tile?(@map_name, {1, 1})

      {:ok, map} = Maps.fetch_map(@map_name)

      assert Maps.walkable_tile?(map, {3, 1})
    end

    test "when tile is a brick" do
      refute Maps.walkable_tile?(@map_name, {1, 5})

      {:ok, map} = Maps.fetch_map(@map_name)

      refute Maps.walkable_tile?(map, {3, 5})
    end

    test "when tile is outside map dimensions" do
      refute Maps.walkable_tile?(@map_name, {0, 1})
      refute Maps.walkable_tile?(@map_name, {-1, 1})

      {:ok, map} = Maps.fetch_map(@map_name)

      refute Maps.walkable_tile?(map, {1, 9})
    end
  end

  describe "get_random_map_walkable_tile?/2" do
    {:ok, map} = Maps.fetch_map(@map_name)

    tile = Maps.get_random_map_walkable_tile(map)

    assert Maps.walkable_tile?(@map_name, tile)

    Enum.each(0..50, fn _ ->
      tile = Maps.get_random_map_walkable_tile(map)

      assert Maps.walkable_tile?(@map_name, tile)
    end)
  end

  describe "get_random_map_name/0" do
    assert Maps.get_random_map_name() == @map_name
  end

  describe "bild_matrix/1" do
    test "builds a matrix of positions" do
      {:ok, map} = Maps.fetch_map(@map_name)

      assert [[{0, 9} | _] = first_row | _] = matrix = Maps.build_matrix(map)

      assert Enum.count(matrix) == 10
      assert Enum.count(first_row) == 10
    end
  end

  describe "list_walkable_surroundings/2" do
    test "builds a matrix of walkable positions" do
      {:ok, map} = Maps.fetch_map(@map_name)

      assert Maps.list_walkable_surroundings(map, {1, 6}) == [
               {1, 6},
               {1, 7},
               {2, 6},
               {2, 7},
               {2, 5}
             ]
    end
  end

  describe "handle_new_position/2" do
    test "when new position is valid" do
      assert Maps.handle_new_position(@map_name, {2, 2}, :up) == {2, 3}
      assert Maps.handle_new_position(@map_name, {2, 2}, :down) == {2, 1}
      assert Maps.handle_new_position(@map_name, {2, 2}, :left) == {1, 2}
      assert Maps.handle_new_position(@map_name, {2, 2}, :right) == {3, 2}
    end

    test "when new position is invalid" do
      assert Maps.handle_new_position(@map_name, {1, 4}, :up) == {1, 4}
      assert Maps.handle_new_position(@map_name, {1, 1}, :down) == {1, 1}
      assert Maps.handle_new_position(@map_name, {1, 1}, :left) == {1, 1}
      assert Maps.handle_new_position(@map_name, {3, 1}, :right) == {3, 1}
    end
  end
end
