defmodule Game.Players do
  import Game.Maps, only: [is_valid_direction: 1]

  alias Game.Maps
  alias Game.Maps.Map, as: GameMap
  alias Game.Players.{Names, Player, PlayerRegistry, PlayerServer, PlayerSupervisor}

  defdelegate generate_name, to: Names, as: :generate

  def provide_player(player_name) when is_binary(player_name) do
    if PlayerRegistry.player_exist?(player_name) do
      PlayerServer.get_player(player_name)
    else
      player_name
      |> build_player()
      |> PlayerSupervisor.start_player()

      player_name
      |> PlayerServer.get_player()
      |> tap(&broadcast_player(&1, :new_player))
    end
  end

  def get_player(player_name), do: PlayerServer.get_player(player_name)

  def move_player(%Player{name: player_name}, direction) when is_valid_direction(direction) do
    player_name
    |> PlayerServer.move_player(direction)
    |> tap(&broadcast_player(&1, :updated_player))
  end

  def attack_surroundings(%Player{} = attacker_player) do
    {:ok, map} = Maps.fetch_map(attacker_player.map_name)
    attacker_surroundings = Maps.list_surroundings(map, attacker_player.position)

    map
    |> list_players_by()
    |> Enum.filter(&(&1.name != attacker_player.name and &1.position in attacker_surroundings))
    |> Enum.each(fn player ->
      player.name
      |> PlayerServer.kill_player()
      |> tap(&broadcast_player(&1, :updated_player))
    end)
  end

  def list_players_by(%GameMap{name: map_name}) do
    PlayerSupervisor
    |> Supervisor.which_children()
    |> Enum.map(fn {_, pid, _, _} ->
      [player_name] = Registry.keys(PlayerRegistry, pid)

      PlayerServer.get_player(player_name)
    end)
    |> Enum.filter(&(&1.map_name == map_name))
  end

  defp build_player(player_name) do
    map_name = Maps.get_random_map_name()
    position = Maps.get_random_map_walkable_tile(map_name)

    Player.new(name: player_name, map_name: map_name, position: position)
  end

  def subscribe_to_players(%GameMap{} = map) do
    Phoenix.PubSub.subscribe(Game.PubSub, map_topic(map))
  end

  defp broadcast_player(%Player{} = player, event) do
    Phoenix.PubSub.broadcast(Game.PubSub, map_topic(player), {event, player})
  end

  defp map_topic(%Player{} = player), do: "map_name:" <> player.map_name
  defp map_topic(%GameMap{} = map), do: "map_name:" <> map.name
end
