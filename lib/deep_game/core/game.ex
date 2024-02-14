defmodule DeepGame.Core.Game do
  defstruct [
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
  @ball_r 5

  # APIs for GameLoop
  def new() do
    paddle_x = div(@screen_width - @paddle_width, 2)
    paddle_y = @screen_height - 100

    ball_x = paddle_x + div(@paddle_width, 2) - @ball_r
    ball_y = paddle_y - @ball_r * 2

    %__MODULE__{
      paddle: %{x: paddle_x, y: paddle_y, width: @paddle_width, height: @paddle_height},
      ball: %{
        x: ball_x,
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
  end

  defp update_paddle(
         %__MODULE__{paddle: %{x: x, y: y}, paddle_direction: paddle_direction} = game,
         ts
       ) do
    x = x + paddle_direction * @paddle_speed * ts
    x = max(0, x)
    x = min(@screen_width - @paddle_width, x)
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
      x < 0 ->
        {abs(x), dx * -1}

      x + 2 * @ball_r > @screen_width ->
        d = x + 2 * @ball_r - @screen_width
        x = @screen_width - d - 2 * @ball_r
        {x, dx * -1}

      true ->
        {x, dx}
    end
  end

  defp maybe_bounce_top(y, dy) do
    cond do
      y < 0 -> {abs(y), dy * -1}
      true -> {y, dy}
    end
  end

  defp maybe_bounce_paddle(_, y, -1, _) do
    {y, -1}
  end

  defp maybe_bounce_paddle(x, y, dy, paddel) do
    if y + 2 * @ball_r > paddel.y and x > paddel.x - @ball_r and
         x < paddel.x + paddel.width - @ball_r do
      d = y + 2 * @ball_r - paddel.y
      y = paddel.y - d - 2 * @ball_r
      {y, -1}
    else
      {y, dy}
    end
  end

  # LiveView process will actually render DOM
  def render(game) do
    Map.take(game, [:paddle, :ball])
  end

  # For DRL
  def get_actions(_env) do
    [:left, :stop, :right]
  end
end
