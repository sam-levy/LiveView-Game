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
      assert %Player{position: {1, 2}, last_moved_at: last_moved_at} =
               PlayerServer.move_player(player.name, :up)

      assert last_moved_at != player.last_moved_at

      assert %Player{position: {2, 2}} = PlayerServer.move_player(player.name, :right)
      assert %Player{position: {2, 1}} = PlayerServer.move_player(player.name, :down)
      assert %Player{position: {1, 1}} = PlayerServer.move_player(player.name, :left)
    end

    test "doesn't move a player when the new position is a brick", %{player: player} do
      assert %Player{position: {1, 1}, last_moved_at: last_moved_at} =
               PlayerServer.move_player(player.name, :left)

      assert last_moved_at != player.last_moved_at

      assert %Player{position: {1, 1}} = PlayerServer.move_player(player.name, :down)
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
