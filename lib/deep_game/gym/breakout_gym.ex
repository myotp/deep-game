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

  # def get_observation(game) do
  #   render_info = Breakout.render_info(game)

  #   background()
  #   |> put_paddle(render_info.paddle)
  #   |> put_ball(render_info.ball)
  #   |> create_nx()
  # end

  def get_observation(game) do
    render_info = Breakout.render_info(game)

    #    t = background()

    # |> put_paddle(render_info.paddle)

    #      |> put_ball(render_info.ball)
    {{paddle_r, paddle_c}, paddle} = get_paddle(render_info.paddle)
    {{ball_r, ball_c}, ball} = get_ball(render_info.ball)

    render_nx({{paddle_r, paddle_c}, paddle}, {{ball_r, ball_c}, ball})
  end

  defn render_nx({{paddle_r, paddle_c}, paddle}, {{ball_r, ball_c}, ball}) do
    background()
    |> Nx.put_slice([paddle_r, paddle_c], paddle)
    |> Nx.put_slice([ball_r, ball_c], ball)
    |> create_nx()
  end

  defn create_nx(t) do
    t
    |> reverse_y()
    |> condense()
  end

  defn background() do
    Nx.broadcast(0, {@screen_height, @screen_width})
  end

  defp get_paddle(paddle) do
    row = round(paddle.y)
    col = round(paddle.x - paddle.width / 2)
    paddle_t = Nx.broadcast(128, {paddle.height, paddle.width})
    {{row, col}, paddle_t}
  end

  defp put_paddle(background, paddle) do
    row = round(paddle.y)
    col = round(paddle.x - paddle.width / 2)
    paddle_t = Nx.broadcast(128, {paddle.height, paddle.width})
    Nx.put_slice(background, [row, col], paddle_t)
  end

  defp get_ball(ball) do
    row = round(ball.y)
    col = round(ball.x - ball.width / 2)

    ball_t =
      Nx.multiply(
        Nx.broadcast(200, {ball.height, ball.width}),
        Utils.ball_gray_scales(round(ball.width / 2))
      )

    {{row, col}, ball_t}
  end

  defp put_ball(background, ball) do
    row = round(ball.y)
    col = round(ball.x - ball.width / 2)

    ball_t =
      Nx.multiply(
        Nx.broadcast(200, {ball.height, ball.width}),
        Utils.ball_gray_scales(round(ball.width / 2))
      )

    Nx.put_slice(background, [row, col], ball_t)
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
