defmodule GameWeb.LobbyLive do
  use GameWeb, :live_view

  alias Game.Players

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, player_name: Players.generate_name())}
  end

  @impl true
  def handle_event("rename_player", %{"player_name" => player_name}, socket) do
    socket = assign(socket, player_name: player_name)

    {:noreply, socket}
  end

  @impl true
  def handle_event("play", _, socket) do
    path = Routes.game_path(socket, :game, name: socket.assigns.player_name)

    {:noreply, push_redirect(socket, to: path)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="">
      <h1>Type your hero's name</h1>
      <form phx-change="rename_player" phx-submit="play">
        <input type="text" name="player_name" value={@player_name}/>
        <input type="submit" value="Play!">
      </form>
    </div>
    """
  end
end
