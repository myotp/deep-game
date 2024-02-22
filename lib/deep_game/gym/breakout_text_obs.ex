defmodule DeepGame.Gym.BreakoutTextObs do
  def game_to_observation(game) do
    [
      game.ball.speed_x,
      game.ball.speed_y,
      game.ball.x,
      game.ball.y,
      game.paddle.x,
      game.paddle.y
    ]
  end
end
