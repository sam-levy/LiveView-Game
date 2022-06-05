defmodule Game.Players.PlayerSupervisor do
  use DynamicSupervisor

  alias Game.Players.{Player, PlayerServer}

  def start_link(arg) do
    DynamicSupervisor.start_link(__MODULE__, arg, name: __MODULE__)
  end

  def start_player(%Player{} = player) do
    DynamicSupervisor.start_child(__MODULE__, {PlayerServer, player})
  end

  @impl true
  def init(_arg) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end
end
