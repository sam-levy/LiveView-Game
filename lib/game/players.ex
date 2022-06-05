defmodule Game.Players do
  alias Game.Maps
  alias Game.Players.{Player, PlayerRegistry, PlayerServer, PlayerSupervisor}

  def provide_player(player_name) when is_binary(player_name) do
    if PlayerRegistry.player_exist?(player_name) do
      PlayerServer.get_player(player_name)
    else
      player_name
      |> build_player()
      |> PlayerSupervisor.start_player()

      PlayerServer.get_player(player_name)
    end
  end

  def move_player(%Player{name: player_name}, direction)
      when direction in ~w[up down left right]a do
    PlayerServer.move_player(player_name, direction)
  end

  defp build_player(player_name) do
    map_name = Maps.get_random_map_name()
    position = Maps.get_random_valid_map_position(map_name)

    Player.new(name: player_name, map_name: map_name, position: position)
  end
end
