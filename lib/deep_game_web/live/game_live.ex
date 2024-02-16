defmodule DeepGameWeb.GameLive do
  use Phoenix.LiveView

  alias DeepGame.Core.Breakout
  alias DeepGame.Core.BreakoutGym

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
    case socket.assigns.game_state do
      :welcome ->
        socket = init_new_game(socket)
        {:noreply, socket}

      :waiting ->
        {:ok, ref} = :timer.send_interval(@game_loop_interval, self(), :tick)

        socket =
          assign(socket,
            game_state: :running,
            timer_ref: ref
          )

        {:noreply, socket}

      _ ->
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
        game = Breakout.handle_input(game, paddle_direction)
        {:noreply, assign(socket, game: game)}
    end
  end

  @impl Phoenix.LiveView
  # Actuall GameLoop
  def handle_info(:tick, socket) do
    game = Breakout.update(socket.assigns.game, @game_loop_interval)
    socket = assign(socket, game: game)
    render_info = Breakout.render_info(game)
    maybe_show_game_heatmap(game)
    socket = render(socket, render_info)
    {:noreply, socket}
  end

  defp maybe_show_game_heatmap(game) do
    if Enum.random(1..1000) < 10 do
      Task.start(fn ->
        BreakoutGym.game_to_heatmap(game)
        |> IO.inspect()
      end)
    end
  end

  defp init_new_game(socket) do
    game = Breakout.new()
    socket = render(socket, Breakout.render_info(game))

    assign(socket,
      game_state: :waiting,
      game: game
    )
  end

  defp render(socket, render_info) do
    case render_info.game_state do
      :running ->
        paddle = render_sprite(render_info, :paddle)
        ball = render_sprite(render_info, :ball)
        assign(socket, paddle: paddle, ball: ball)

      {:finished, :lost} ->
        tref = socket.assigns.timer_ref
        :timer.cancel(tref)
        init_new_game(socket)
    end
  end

  defp render_sprite(render_info, sprite_key) do
    sprite = render_info[sprite_key]
    x = round(sprite.x - sprite.width / 2)
    y = @screen_height - round(sprite.y + sprite.height / 2)
    %{x: x, y: y, width: sprite.width, height: sprite.height}
  end
end
