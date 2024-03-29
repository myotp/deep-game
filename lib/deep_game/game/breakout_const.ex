defmodule DeepGame.Game.BreakoutConst do
  defmacro __using__(_) do
    quote do
      @screen_width 800
      @screen_height 600
      @paddle_width 100
      @paddle_height 10
      @paddle_speed 0.4
      @init_ball_speed 0.4
      @ball_r 8
    end
  end
end
