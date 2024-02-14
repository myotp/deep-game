defmodule DeepGame.Core.Game do
  defstruct [:ball_pos, :paddle, paddle_direction: 0]

  @screen_width 800
  @screen_height 600
  @paddle_width 100
  # @paddle_height 10
  @paddle_speed 1

  # APIs for GameLoop
  def new() do
    paddle_x = div(@screen_width - @paddle_width, 2)
    paddle_y = @screen_height - 100

    %__MODULE__{
      paddle: %{x: paddle_x, y: paddle_y, width: 100, height: 10}
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

  def update(game, time) do
    game
    |> update_paddle(time)
  end

  defp update_paddle(
         %__MODULE__{paddle: %{x: x, y: y}, paddle_direction: paddle_direction} = game,
         time
       ) do
    x = x + paddle_direction * @paddle_speed * time
    x = max(0, x)
    x = min(@screen_width - @paddle_width, x)
    %__MODULE__{game | paddle: %{x: x, y: y}}
  end

  # LiveView process will actually render DOM
  def render(game) do
    Map.take(game, [:paddle])
  end

  # For DRL
  def get_actions(_env) do
    [:left, :stop, :right]
  end
end
