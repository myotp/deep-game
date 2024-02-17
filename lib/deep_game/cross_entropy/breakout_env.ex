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
    %{
      ball
      | y: Enum.random(350..420),
        x: Enum.random(100..700),
        speed_y: random_speed_y(),
        speed_x: random_speed_x()
    }
  end

  defp random_speed_x() do
    0.5 * Enum.random([1, -1]) * Enum.random(85..115) / 100
  end

  defp random_speed_y() do
    -0.5 * Enum.random(85..115) / 100
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
    [
      game.ball.speed_x,
      game.ball.speed_y,
      game.ball.x / 800,
      game.ball.y / 600,
      game.paddle.x / 800,
      game.paddle.y / 600
    ]
  end
end
