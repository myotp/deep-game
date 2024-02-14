defmodule DeepGameWeb.GameLive do
  use Phoenix.LiveView

  alias DeepGame.Core.Game

  @game_loop_interval 16

  @screen_height 600

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    socket =
      assign(socket,
        username: "test",
        game_state: :welcome,
        game: nil,
        timer_ref: nil
      )

    {:ok, socket}
  end

  @impl Phoenix.LiveView
  def handle_event("keyup", %{"key" => " "}, socket) do
    if socket.assigns.game_state == :welcome do
      game = Game.new()
      socket = render(socket, Game.render(game))
      {:ok, ref} = :timer.send_interval(@game_loop_interval, self(), :tick)

      socket =
        assign(socket,
          game_state: :running,
          game: game,
          timer_ref: ref
        )

      {:noreply, socket}
    else
      IO.puts("Game already started")
      {:noreply, socket}
    end
  end

  def handle_event(event, params, socket) do
    paddle_direction =
      case {event, params} do
        {"keyup", %{"key" => "ArrowLeft"}} -> :stop
        {"keyup", %{"key" => "ArrowRight"}} -> :stop
        {"keydown", %{"key" => "ArrowLeft"}} -> :left
        {"keydown", %{"key" => "ArrowRight"}} -> :right
        _ -> nil
      end

    case paddle_direction do
      nil ->
        {:noreply, socket}

      _ ->
        game = socket.assigns.game
        game = Game.handle_input(game, paddle_direction)
        {:noreply, assign(socket, game: game)}
    end
  end

  @impl Phoenix.LiveView
  # Actuall GameLoop
  def handle_info(:tick, socket) do
    game = Game.update(socket.assigns.game, @game_loop_interval)
    socket = assign(socket, game: game)
    render_info = Game.render(game)
    socket = render(socket, render_info)
    {:noreply, socket}
  end

  defp render(socket, render_info) do
    paddle = render_sprite(render_info, :paddle)
    ball = render_sprite(render_info, :ball)
    assign(socket, paddle: paddle, ball: ball)
  end

  defp render_sprite(render_info, sprite_key) do
    sprite = render_info[sprite_key]
    x = round(sprite.x - sprite.width / 2)
    y = @screen_height - round(sprite.y + sprite.height / 2)
    %{x: x, y: y, width: sprite.width, height: sprite.height}
  end
end
