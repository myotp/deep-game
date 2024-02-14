defmodule DeepGame.Core.Game do
  defstruct [
    :game_state,
    :ball,
    :paddle,
    paddle_direction: 0,
    ball_direction_x: 1,
    ball_direction_y: -1
  ]

  @screen_width 800
  @screen_height 600
  @paddle_width 100
  @paddle_height 10
  @paddle_speed 0.3
  @init_ball_speed 0.1
  @ball_r 8

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

  defp update_ball(%__MODULE__{ball: ball, ball_direction_x: dx, ball_direction_y: dy} = game, ts) do
    %{x: x, y: y, speed_x: speed_x, speed_y: speed_y} = ball
    x = x + speed_x * dx * ts
    y = y + speed_y * dy * ts

    {x, dx} = maybe_bounce_x(x, dx)
    {y, dy} = maybe_bounce_top(y, dy)
    {y, dy} = maybe_bounce_paddle(x, y, dy, game.paddle)
    %__MODULE__{game | ball: %{ball | x: x, y: y}, ball_direction_x: dx, ball_direction_y: dy}
  end

  defp maybe_bounce_x(x, dx) do
    cond do
      x < @ball_r ->
        x = @ball_r - x + @ball_r
        {x, dx * -1}

      x + @ball_r > @screen_width ->
        d = x + @ball_r - @screen_width
        x = @screen_width - d - @ball_r
        {x, dx * -1}

      true ->
        {x, dx}
    end
  end

  defp maybe_bounce_top(y, dy) do
    cond do
      y + @ball_r > @screen_height ->
        d = y + @ball_r - @screen_height
        y = @screen_height - d - @ball_r
        {y, dy * -1}

      true ->
        {y, dy}
    end
  end

  defp maybe_bounce_paddle(_, y, 1, _) do
    {y, 1}
  end

  defp maybe_bounce_paddle(x, y, dy, paddle) do
    if y - @ball_r - paddle.height / 2 < paddle.y and
         x > paddle.x - paddle.width / 2 and
         x < paddle.x + paddle.width / 2 do
      d = paddle.y - (y - @ball_r - paddle.height / 2)
      y = y + d
      {y, 1}
    else
      {y, dy}
    end
  end

  # LiveView process will actually render DOM
  def render(game) do
    sprite_list = [:paddle, :ball]
    Map.take(game, [:game_state | sprite_list])
  end

  # For DRL
  def get_actions(_env) do
    [:left, :stop, :right]
  end
end
