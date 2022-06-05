defmodule Game.Application do
  use Application

  @impl true
  def start(_type, _args) do
    children = [
      Game.Players.PlayerRegistry,
      Game.Players.PlayerSupervisor,
      GameWeb.Telemetry,
      {Phoenix.PubSub, name: Game.PubSub},
      GameWeb.Endpoint
    ]

    opts = [strategy: :one_for_one, name: Game.Supervisor]
    Supervisor.start_link(children, opts)
  end

  @impl true
  def config_change(changed, _new, removed) do
    GameWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
