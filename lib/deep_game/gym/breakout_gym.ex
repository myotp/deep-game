defmodule DeepGame.Gym.BreakoutGym do
  use DeepGame.Game.BreakoutConst
  alias DeepGame.Gym.Utils
  import Nx.Defn

  alias DeepGame.Game.Breakout
  # DRL Environment APIs
  def get_actions(_game) do
    [:left, :stop, :right]
  end

  def is_done?(game) do
    game.state != :running
  end

  def action(game, action) do
    Breakout.handle_input(game, action)
  end

  def get_observation(game) do
    render_info = Breakout.render_info(game)
    {{paddle_r, paddle_c}, paddle} = paddle_to_nx(render_info.paddle)
    {{ball_r, ball_c}, ball} = ball_to_nx(render_info.ball)
    render_nx({{paddle_r, paddle_c}, paddle}, {{ball_r, ball_c}, ball})
  end

  defp paddle_to_nx(paddle) do
    row = round(paddle.y)
    col = round(paddle.x - paddle.width / 2)
    paddle_t = Nx.broadcast(128, {paddle.height, paddle.width})
    {{row, col}, paddle_t}
  end

  defp ball_to_nx(ball) do
    row = round(ball.y)
    col = round(ball.x - ball.width / 2)

    ball_t =
      Nx.multiply(
        Nx.broadcast(200, {ball.height, ball.width}),
        Utils.ball_gray_scales(round(ball.width / 2))
      )

    {{row, col}, ball_t}
  end

  defn render_nx({{paddle_r, paddle_c}, paddle}, {{ball_r, ball_c}, ball}) do
    background()
    |> Nx.put_slice([paddle_r, paddle_c], paddle)
    |> Nx.put_slice([ball_r, ball_c], ball)
    |> reverse_y()
    |> condense()
  end

  defn background() do
    Nx.broadcast(0, {@screen_height, @screen_width})
  end

  defn reverse_y(t) do
    Nx.reverse(t, axes: [0])
  end

  defn condense(t) do
    {row, col} = Nx.shape(t)

    t
    |> Nx.window_sum({4, 4})
    |> Nx.slice_along_axis(0, row - 3, axis: 0, strides: 4)
    |> Nx.slice_along_axis(0, col - 3, axis: 1, strides: 4)
  end
end
