defmodule GameWeb.LobbyLive do
  use GameWeb, :live_view

  alias Game.Players

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, name: Players.generate_name())}
  end

  @impl true
  def handle_event("play", _, socket) do
    path = Routes.game_path(socket, :game, name: socket.assigns.name)

    {:noreply, push_redirect(socket, to: path, replace: true)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="">
      <h1>Type your hero's name</h1>
      <input type="text" value={@name}/>
      <button phx-click="play">Play!</button>
    </div>
    """
  end
end
