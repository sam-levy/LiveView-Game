defmodule Game.Players.PlayerRegistry do
  def child_spec(_arg) do
    %{id: __MODULE__, start: {__MODULE__, :start_link, []}}
  end

  def start_link do
    Registry.start_link(keys: :unique, name: __MODULE__)
  end

  def player_exist?(player_name) when is_binary(player_name) do
    case Registry.lookup(__MODULE__, player_name) do
      [{_pid, _}] -> true
      [] -> false
    end
  end

  def build_process_name(player_name) when is_binary(player_name) do
    {:via, Registry, {__MODULE__, player_name}}
  end
end
