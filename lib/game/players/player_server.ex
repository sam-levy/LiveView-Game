defmodule Game.Players.PlayerServer do
  use GenServer, restart: :transient

  alias Game.Players.{Player, PlayerRegistry}
  alias Game.Maps

  def start_link(%Player{} = player) do
    GenServer.start_link(__MODULE__, player, name: name(player.name))
  end

  def get_player(player_name) do
    GenServer.call(name(player_name), :get_player)
  end

  def move_player(player_name, direction) do
    GenServer.call(name(player_name), {:move_player, direction})
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
    player = handle_player_movement(player, direction)

    {:reply, player, player}
  end

  defp name(player_name), do: PlayerRegistry.build_process_name(player_name)

  defp handle_player_movement(player, direction) do
    new_position = build_new_position(player.position, direction)

    if Maps.walkable_tile?(player.map_name, new_position),
      do: %{player | position: new_position},
      else: player
  end

  defp build_new_position({x, y}, :up), do: {x, y + 1}
  defp build_new_position({x, y}, :down), do: {x, y - 1}
  defp build_new_position({x, y}, :left), do: {x - 1, y}
  defp build_new_position({x, y}, :right), do: {x + 1, y}
end
