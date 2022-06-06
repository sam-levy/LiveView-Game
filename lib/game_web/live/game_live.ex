defmodule GameWeb.GameLive do
  use GameWeb, :live_view

  alias Game.Maps
  alias Game.Players

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket, temporary_assigns: [players_by_position: %{}]}
  end

  @impl true
  def handle_params(%{"name" => my_player_name}, _url, socket) do
    my_player = Players.provide_player(my_player_name)
    {:ok, map} = Maps.fetch_map(my_player.map_name)

    players = Players.list_players_by(map)
    players_by_name = Map.new(players, &{&1.name, &1})

    if connected?(socket), do: Players.subscribe_to_players(map)

    socket =
      assign(socket,
        map: map,
        my_player_name: my_player.name,
        players_by_name: players_by_name,
        players_by_position: build_players_by_position(players_by_name)
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
    players_by_name = Map.put(socket.assigns.players_by_name, player.name, player)

    socket =
      assign(socket,
        players_by_name: players_by_name,
        players_by_position: build_players_by_position(players_by_name)
      )

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
  def render(assigns) do
    ~H"""
    <div class="map-wrapper">
      <div class="map">
        <%= for rows <- Maps.build_matrix(@map) do %>
          <div class="map-row">
            <.brick/>

            <%= for position <- rows do %>
              <%= if Maps.is_brick?(@map, position) do %>
                <.brick/>
              <% else %>
                <.tile players={players_from_position(@players_by_position, position, @my_player_name)}/>
              <% end %>
            <% end %>

            <.brick/>
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

      <button phx-click="move" phx-value-direction="up">ATTACK!</button>
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

  def tile(%{players: players} = assigns) do
    ~H"""
    <div class="map-tile">
      <%= for player <- players do %>
        <div class="">
          <%= player.name %>
        </div>
      <% end %>
    </div>
    """
  end

  defp build_players_by_position(players_by_name) do
    players_by_name
    |> Map.values()
    |> Enum.reduce(%{}, fn player, acc ->
      case Map.get(acc, player.position) do
        nil -> Map.put(acc, player.position, [player])
        players -> Map.put(acc, player.position, [player | players])
      end
    end)
  end

  defp players_from_position(players_by_position, position, my_player_name)
       when is_binary(my_player_name) do
    my_player = Players.get_player(my_player_name)

    players_from_position(players_by_position, position, my_player)
  end

  defp players_from_position(players_by_position, position, %{position: position} = my_player) do
    case Map.get(players_by_position, position, []) do
      [my_player] -> [my_player]
      players -> [my_player | Enum.reject(players, &(&1.name == my_player.name))]
    end
  end

  defp players_from_position(players_by_position, position, _my_player) do
    Map.get(players_by_position, position, [])
  end
end
