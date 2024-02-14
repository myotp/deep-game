defmodule DeepGame.Core.Game do
  defstruct [:ball_pos, left_key: :up, right_key: :up]

  # APIs for GameLoop
  def new() do
  end

  def handle_input(game, _) do
    game
  end

  def update(game, _time) do
    game
  end

  def render(_) do
    :todo
  end

  # For DRL
  def get_actions() do
    [{:keydown, :left}, {:keydown, :right}, {:keyup, :left}, {:keyup, :right}]
  end
end
