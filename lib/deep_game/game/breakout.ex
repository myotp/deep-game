defmodule DeepGame.Game.Breakout do
  use DeepGame.Game.BreakoutConst

  defstruct [
    :game_state,
    :ball,
    :paddle,
    paddle_direction: 0
  ]

  # APIs for GameLoop
  def new() do
    paddle_y = 100
    ball_y = paddle_y + @paddle_height / 2 + @ball_r

    %__MODULE__{
      game_state: :running,
      paddle: %{
        x: @screen_width / 2,
        y: paddle_y,
        width: @paddle_width,
        height: @paddle_height
      },
      ball: %{
        x: @screen_width / 2,
        y: ball_y,
        speed_x: @init_ball_speed,
        speed_y: @init_ball_speed,
        width: @ball_r * 2,
        height: @ball_r * 2
      }
    }
  end

  def handle_input(game, input) do
    paddle_direction =
      case input do
        :stop -> 0
        :left -> -1
        :right -> 1
      end

    %__MODULE__{game | paddle_direction: paddle_direction}
  end

  def update(game, ts) do
    game
    |> update_paddle(ts)
    |> update_ball(ts)
    |> check_lost()
  end

  defp check_lost(game) do
    if game.ball.y < @ball_r do
      %__MODULE__{game | game_state: {:finished, :lost}}
    else
      game
    end
  end

  defp update_paddle(
         %__MODULE__{paddle: %{x: x, y: y}, paddle_direction: paddle_direction} = game,
         ts
       ) do
    x = x + paddle_direction * @paddle_speed * ts
    x = max(@paddle_width / 2, x)
    x = min(@screen_width - @paddle_width / 2, x)
    %__MODULE__{game | paddle: %{game.paddle | x: x, y: y}}
  end

  defp update_ball(%__MODULE__{ball: ball} = game, ts) do
    %{x: x, y: y, speed_x: speed_x, speed_y: speed_y} = ball
    x = x + speed_x * ts
    y = y + speed_y * ts

    {x, speed_x} = maybe_bounce_x(x, speed_x)
    {y, speed_y} = maybe_bounce_top(y, speed_y)
    {y, speed_y} = maybe_bounce_paddle(x, y, speed_y, game.paddle)
    %__MODULE__{game | ball: %{ball | x: x, y: y, speed_x: speed_x, speed_y: speed_y}}
  end

  defp maybe_bounce_x(x, speed_x) do
    cond do
      x < @ball_r ->
        x = @ball_r - x + @ball_r
        {x, speed_x * -1}

      x + @ball_r > @screen_width ->
        d = x + @ball_r - @screen_width
        x = @screen_width - d - @ball_r
        {x, speed_x * -1}

      true ->
        {x, speed_x}
    end
  end

  defp maybe_bounce_top(y, speed_y) do
    cond do
      y + @ball_r > @screen_height ->
        d = y + @ball_r - @screen_height
        y = @screen_height - d - @ball_r
        {y, speed_y * -1}

      true ->
        {y, speed_y}
    end
  end

  defp maybe_bounce_paddle(_, y, speed_y, _) when speed_y > 0 do
    {y, speed_y}
  end

  defp maybe_bounce_paddle(x, y, speed_y, paddle) do
    if y - @ball_r - paddle.height / 2 < paddle.y and
         y - paddle.height / 2 > paddle.y and
         x > paddle.x - paddle.width / 2 and
         x < paddle.x + paddle.width / 2 do
      d = paddle.y - (y - @ball_r - paddle.height / 2)
      y = y + d
      {y, speed_y * -1}
    else
      {y, speed_y}
    end
  end

  # LiveView process will actually render DOM
  def render_info(game) do
    sprite_list = [:paddle, :ball]
    Map.take(game, [:game_state | sprite_list])
  end
end
