defmodule DeepGame.Gym.BreakoutGuiObs do
  use DeepGame.Game.BreakoutConst
  import Nx.Defn
  alias DeepGame.Game.Breakout
  alias DeepGame.Gym.Utils

  def game_to_observation(game) do
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

  def render_nx({{paddle_r, paddle_c}, paddle}, {{ball_r, ball_c}, ball}) do
    background()
    |> Nx.put_slice([paddle_r, paddle_c], paddle)
    |> Nx.put_slice([ball_r, ball_c], ball)
    |> reverse_y()
    |> downsize_with_cnn()
  end

  defn background() do
    Nx.broadcast(0, {@screen_height, @screen_width})
  end

  defn reverse_y(t) do
    Nx.reverse(t, axes: [0])
  end

  defn naive_downsize(t) do
    {row, col} = Nx.shape(t)

    t
    |> Nx.window_sum({4, 4})
    |> Nx.slice_along_axis(0, row - 3, axis: 0, strides: 4)
    |> Nx.slice_along_axis(0, col - 3, axis: 1, strides: 4)
  end

  def downsize_with_cnn(t) do
    {row, col} = Nx.shape(t)
    model = build_model(row, col)
    {_init_fn, pred_fn} = Axon.build(model)
    params = %{"conv_0" => %{"kernel" => filter_2x2()}}
    input = Nx.reshape(t, {1, row, col, 1})
    result = pred_fn.(params, input)
    {1, row, col, 1} = Nx.shape(result)
    Nx.reshape(result, {row, col})
  end

  def filter_2x2() do
    Nx.tensor([
      [1, 1],
      [1, 1]
    ])
    |> Nx.reshape({2, 2, 1, 1})
  end

  def build_model(x, y) do
    Axon.input("input", shape: {nil, x, y, 1})
    |> Axon.conv(1, kernel_size: {2, 2}, padding: :valid, use_bias: false)
    # maybe max_pool?
    |> Axon.avg_pool(kernel_size: {4, 4}, padding: :valid)
  end
end
