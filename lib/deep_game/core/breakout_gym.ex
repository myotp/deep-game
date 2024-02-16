defmodule DeepGame.Core.BreakoutGym do
  alias DeepGame.Core.Game
  # DRL Environment APIs
  def get_actions(_game) do
    [:left, :stop, :right]
  end

  def is_done?(game) do
    game.state != :running
  end

  def action(game, action) do
    Game.handle_input(game, action)
  end

  def get_observation(game) do
    Game.render_info(game)
  end
end
