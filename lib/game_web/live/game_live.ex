defmodule GameWeb.GameLive do
  use GameWeb, :live_view

  alias Game.Maps
  alias Game.Players

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket, temporary_assigns: [live_players_by_position: %{}]}
  end

  @impl true
  def terminate(_reason, socket) do
    Players.remove_player(socket.assigns.my_player_name)
  end

  @impl true
  def handle_params(%{"name" => my_player_name}, _url, socket) do
    my_player = Players.provide_player(my_player_name)
    {:ok, map} = Maps.fetch_map(my_player.map_name)

    players = Players.list_players_by(map)
    players_by_name = Map.new(players, &{&1.name, &1})

    if connected?(socket), do: Players.subscribe_to_players(map)

    socket =
      socket
      |> assign_players(players_by_name)
      |> assign(
        map: map,
        my_player_name: my_player.name,
        respawn_timer: 0
      )

    {:noreply, socket}
  end

  @impl true
  def handle_params(_params, _url, socket) do
    path = Routes.game_path(socket, :game, name: Players.generate_name())

    {:noreply, push_patch(socket, to: path, replace: true)}
  end

  @impl true
  def handle_info({event, player}, socket) when event in [:new_player, :updated_player] do
    {:noreply, assign_updated_player(socket, player)}
  end

  @impl true
  def handle_info(
        {:killed_player, %{name: name} = player},
        %{assigns: %{my_player_name: name}} = socket
      ) do
    socket =
      socket
      |> assign_updated_player(player)
      |> assign(respawn_timer: 5)

    Process.send_after(self(), :decrease_respawn_timer, 1_000)

    {:noreply, socket}
  end

  @impl true
  def handle_info({:killed_player, player}, socket) do
    {:noreply, assign_updated_player(socket, player)}
  end

  @impl true
  def handle_info({:removed_player, player}, socket) do
    players_by_name = Map.drop(socket.assigns.players_by_name, [player.name])

    {:noreply, assign_players(socket, players_by_name)}
  end

  @impl true
  def handle_info(:decrease_respawn_timer, socket) do
    if socket.assigns.respawn_timer > 0 do
      Process.send_after(self(), :decrease_respawn_timer, 1_000)

      {:noreply, update(socket, :respawn_timer, &(&1 - 1))}
    else
      {:noreply, socket}
    end
  end

  defp assign_updated_player(socket, player) do
    players_by_name = Map.put(socket.assigns.players_by_name, player.name, player)

    assign_players(socket, players_by_name)
  end

  defp assign_players(socket, players_by_name) do
    assign(socket,
      players_by_name: players_by_name,
      live_players_by_position: list_live_players_by_position(players_by_name)
    )
  end

  @impl true
  def handle_event(event, _, %{assigns: %{respawn_timer: timer}} = socket)
      when timer != 0 and event in ["move", "attack"] do
    {:noreply, socket}
  end

  @impl true
  def handle_event("move", %{"direction" => direction}, socket) do
    socket.assigns.my_player_name
    |> Players.get_player()
    |> Players.move_player(String.to_existing_atom(direction))

    {:noreply, socket}
  end

  @impl true
  def handle_event("attack", _, socket) do
    socket.assigns.my_player_name
    |> Players.get_player()
    |> Players.attack_surroundings()

    {:noreply, socket}
  end

  def handle_event("player_action", %{"key" => " "}, socket) do
    socket.assigns.my_player_name
    |> Players.get_player()
    |> Players.attack_surroundings()

    {:noreply, socket}
  end

  @move_keys_up ["ArrowUp", "k", "e"]
  @move_keys_down ["ArrowDown", "j", "d"]
  @move_keys_left ["ArrowLeft", "h", "s"]
  @move_keys_right ["ArrowRight", "l", "f"]

  @valid_move_keys @move_keys_up ++ @move_keys_down ++ @move_keys_left ++ @move_keys_right

  def handle_event("player_action", %{"key" => key}, socket) when key in @valid_move_keys do
    socket.assigns.my_player_name
    |> Players.get_player()
    |> move_player(key)

    {:noreply, socket}
  end

  def handle_event("player_action", _, socket), do: {:noreply, socket}

  defp move_player(player, key) when key in @move_keys_up, do: Players.move_player(player, :up)

  defp move_player(player, key) when key in @move_keys_down,
    do: Players.move_player(player, :down)

  defp move_player(player, key) when key in @move_keys_left,
    do: Players.move_player(player, :left)

  defp move_player(player, key) when key in @move_keys_right,
    do: Players.move_player(player, :right)

  @impl true
  def render(assigns) do
    ~H"""
    <div class="map-wrapper" phx-window-keyup="player_action">
      <div class="map">
        <%= for rows <- Maps.build_matrix(@map) do %>
          <div class="map-row">
            <%= for position <- rows do %>
              <%= if Maps.walkable_tile?(@map, position) do %>
                <.tile players={players_from_position(@live_players_by_position, position, @my_player_name)} my_player_name={@my_player_name}/>
              <% else %>
                <.brick/>
              <% end %>
            <% end %>
          </div>
        <% end %>
      </div>
    </div>

    <div class="buttons-wrapper">
      <div>
        <div class="buttons-d-row">
          <a phx-click="move" phx-value-direction="up" class="buttons-d" style="margin-bottom: -0.5em;">⬆️</a>
        </div>

        <div class="buttons-d-row">
          <a phx-click="move" phx-value-direction="left" class="buttons-d" style="padding-right: 0.5em;">⬅️</a>
          <a phx-click="move" phx-value-direction="right" class="buttons-d">➡️</a>
        </div>

        <div class="buttons-d-row">
          <a phx-click="move" phx-value-direction="down" class="buttons-d" style="margin-top: -0.5em;">⬇️</a>
        </div>
      </div>

      <%= if @respawn_timer > 0 do %>
        <div class="">
          <h2>YOU DIED!</h2>
          <h3>Respawn in: <%= @respawn_timer %></h3>
        </div>
      <% end %>

      <button phx-click="attack">ATTACK!</button>
    </div>
    """
  end

  def brick(assigns) do
    ~H"""
    <div class="map-brick"></div>
    """
  end

  def tile(%{players: []} = assigns) do
    ~H"""
    <div class="map-tile"></div>
    """
  end

  def tile(%{players: [player]} = assigns) do
    ~H"""
    <div class="map-tile">
      <.player player={player} my_player_name={@my_player_name}/>
    </div>
    """
  end

  def tile(%{players: [player | _]} = assigns) do
    ~H"""
    <div class="map-tile">
      <div class="map-tile-count">
        <%= Enum.count(@players) %>
      </div>

      <.player player={player} my_player_name={@my_player_name}/>
    </div>
    """
  end

  def player(%{player: %{name: name}, my_player_name: name} = assigns) do
    ~H"""
    <div class="player" style="background-color: darkgreen;">
      <div>
        <%= name %>
      </div>
    </div>
    """
  end

  def player(assigns) do
    ~H"""
    <div class="player" style="background-color: darkred;">
      <div>
        <%= @player.name %>
      </div>
    </div>
    """
  end

  defp list_live_players_by_position(players_by_name) do
    players_by_name
    |> Map.values()
    |> Enum.reduce(%{}, fn
      %{alive?: true} = player, acc ->
        case Map.get(acc, player.position) do
          nil -> Map.put(acc, player.position, [player])
          players -> Map.put(acc, player.position, [player | players])
        end

      _player, acc ->
        acc
    end)
  end

  defp players_from_position(live_players_by_position, position, my_player_name)
       when is_binary(my_player_name) do
    my_player = Players.get_player(my_player_name)

    players_from_position(live_players_by_position, position, my_player)
  end

  defp players_from_position(
         live_players_by_position,
         position,
         %{alive?: true, position: position} = my_player
       ) do
    case Map.get(live_players_by_position, position, []) do
      [my_player] -> [my_player]
      players -> [my_player | Enum.reject(players, &(&1.name == my_player.name))]
    end
  end

  defp players_from_position(live_players_by_position, position, _my_player) do
    Map.get(live_players_by_position, position, [])
  end
end
