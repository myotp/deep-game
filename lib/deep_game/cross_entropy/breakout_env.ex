defmodule DeepGame.CrossEntropy.BreakoutEnv do
  alias DeepGame.Game.Breakout

  defstruct [:game, :observations]

  def reset() do
    game = Breakout.new()
    %__MODULE__{game: game}
  end

  def observations(env) do
    game_to_observations(env.game)
  end

  def actions() do
    [0, 1, 2]
  end

  def move_ball_random(env) do
    ball = env.game.ball
    x = put_in(env.game.ball, random_ball(ball))
    x
  end

  def random_ball(ball) do
    %{ball | y: 400, x: Enum.random(100..700), speed_y: -0.5, speed_x: Enum.random([-0.5, 0.5])}
  end

  def step(env, action) do
    input = action_to_input(action)
    game = game_update(env.game, input)
    {%__MODULE__{env | game: game}, game_to_observations(game), 1, game_done?(game)}
  end

  def is_done?(env) do
    game_done?(env.game)
  end

  defp game_done?(game) do
    game.game_state != :running
  end

  defp action_to_input(0), do: :stop
  defp action_to_input(1), do: :left
  defp action_to_input(2), do: :right

  defp game_update(game, input) do
    game
    |> Breakout.handle_input(input)
    |> Breakout.update(16)
  end

  defp game_to_observations(game) do
    [game.ball.speed_x, game.ball.speed_y, game.ball.x, game.ball.y, game.paddle.x, game.paddle.y]
  end
end
