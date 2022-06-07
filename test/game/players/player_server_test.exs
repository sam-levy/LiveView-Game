defmodule Game.Players.PlayerServerTest do
  use ExUnit.Case, async: true

  alias Game.Players.{Player, PlayerServer}

  setup do
    player = Player.new(name: "Holdor", map_name: "Winterfell", position: {1, 1})
    player_server_pid = start_supervised!({PlayerServer, player})

    %{player: player, player_server_pid: player_server_pid}
  end

  describe "get_player/1" do
    test "gets a player", %{player: player} do
      assert PlayerServer.get_player(player.name) == player
    end
  end

  describe "move_player/2" do
    test "moves a player", %{player: player} do
      assert PlayerServer.move_player(player.name, :up) == %Player{player | position: {1, 2}}
      assert PlayerServer.move_player(player.name, :right) == %Player{player | position: {2, 2}}
      assert PlayerServer.move_player(player.name, :down) == %Player{player | position: {2, 1}}
      assert PlayerServer.move_player(player.name, :left) == %Player{player | position: {1, 1}}
    end

    test "doesn't move a player when the new position is a brick", %{player: player} do
      assert PlayerServer.move_player(player.name, :left) == %Player{player | position: {1, 1}}
      assert PlayerServer.move_player(player.name, :down) == %Player{player | position: {1, 1}}
    end
  end

  describe "kill_player/1" do
    test "kills a player", %{player: player} do
      assert PlayerServer.kill_player(player.name) == %Player{player | alive?: false}
    end
  end

  describe "remove_player/1" do
    test "removes a player", %{player: player, player_server_pid: player_server_pid} do
      assert PlayerServer.remove_player(player.name) == :ok

      refute Process.alive?(player_server_pid)
    end
  end

  describe "handle_info/2 for :respawn_player" do
    test "respawns a player", %{player: player, player_server_pid: player_server_pid} do
      assert PlayerServer.kill_player(player.name) == %Player{player | alive?: false}

      send(player_server_pid, :respawn_player)

      assert %Player{alive?: true} = PlayerServer.get_player(player.name)
    end
  end
end
