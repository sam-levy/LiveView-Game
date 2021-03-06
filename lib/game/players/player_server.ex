defmodule Game.Players.PlayerServer do
  use GenServer, restart: :transient

  import Game.Maps, only: [is_valid_direction: 1]

  alias Game.Players
  alias Game.Players.{Player, PlayerRegistry}
  alias Game.Maps

  # Five seconds
  @respawn_timeout 5_000
  # One minute
  @remove_timeout 60_000

  def start_link(%Player{} = player) do
    GenServer.start_link(__MODULE__, player, name: process_name(player.name))
  end

  def get_player(player_name) when is_binary(player_name) do
    GenServer.call(process_name(player_name), :get_player)
  end

  def move_player(player_name, direction)
      when is_binary(player_name)
      when is_valid_direction(direction) do
    GenServer.call(process_name(player_name), {:move_player, direction})
  end

  def kill_player(player_name) when is_binary(player_name) do
    GenServer.call(process_name(player_name), :kill_player)
  end

  def remove_player(player_name) when is_binary(player_name) do
    GenServer.stop(process_name(player_name))
  end

  @impl true
  def init(player) do
    Process.send_after(self(), :remove_player, @remove_timeout)

    {:ok, player}
  end

  @impl true
  def handle_call(:get_player, _from, player) do
    {:reply, player, player}
  end

  @impl true
  def handle_call({:move_player, direction}, _from, player) do
    new_position = Maps.handle_new_position(player.map_name, player.position, direction)
    player = %{player | position: new_position, last_moved_at: NaiveDateTime.utc_now()}

    {:reply, player, player}
  end

  @impl true
  def handle_call(:kill_player, _from, player) do
    player = %{player | alive?: false}

    Process.send_after(self(), :respawn_player, @respawn_timeout)

    {:reply, player, player}
  end

  @impl true
  def handle_info(:respawn_player, player) do
    position = Maps.get_random_map_walkable_tile(player.map_name)
    player = %{player | alive?: true, position: position}

    Players.broadcast_player(player, :updated_player)

    {:noreply, player}
  end

  @impl true
  def handle_info(:remove_player, player) do
    three_mins_ago = NaiveDateTime.utc_now() |> NaiveDateTime.add(-180)

    case NaiveDateTime.compare(player.last_moved_at, three_mins_ago) do
      :lt ->
        Players.broadcast_player(player, :removed_player)

        {:stop, :normal, player}

      _ ->
        Process.send_after(self(), :remove_player, @remove_timeout)

        {:noreply, player}
    end
  end

  defp process_name(player_name), do: PlayerRegistry.build_process_name(player_name)
end
