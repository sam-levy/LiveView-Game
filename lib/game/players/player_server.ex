defmodule Game.Players.PlayerServer do
  use GenServer, restart: :transient

  alias Game.Players
  alias Game.Players.{Player, PlayerRegistry}
  alias Game.Maps

  @death_timeout 5_000

  def start_link(%Player{} = player) do
    GenServer.start_link(__MODULE__, player, name: process_name(player.name))
  end

  def get_player(player_name) when is_binary(player_name) do
    GenServer.call(process_name(player_name), :get_player)
  end

  def move_player(player_name, direction) when is_binary(player_name) do
    GenServer.call(process_name(player_name), {:move_player, direction})
  end

  def kill_player(player_name) when is_binary(player_name) do
    GenServer.call(process_name(player_name), :kill_player)
  end

  @impl true
  def init(player) do
    {:ok, player}
  end

  @impl true
  def handle_call(:get_player, _from, player) do
    {:reply, player, player}
  end

  @impl true
  def handle_call({:move_player, direction}, _from, player) do
    new_position = Maps.handle_new_position(player.map_name, player.position, direction)
    player = %{player | position: new_position}

    {:reply, player, player}
  end

  @impl true
  def handle_call(:kill_player, _from, player) do
    player = %{player | alive?: false}

    Process.send_after(self(), :respawn_player, @death_timeout)

    {:reply, player, player}
  end

  @impl true
  def handle_info(:respawn_player, player) do
    position = Maps.get_random_map_walkable_tile(player.map_name)
    player = %{player | alive?: true, position: position}

    Players.broadcast_player(player, :updated_player)

    {:noreply, player}
  end

  defp process_name(player_name), do: PlayerRegistry.build_process_name(player_name)
end
