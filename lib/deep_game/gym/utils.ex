defmodule DeepGame.Gym.Utils do
  def ball_gray_scales(r) do
    top_right = Nx.tensor(naive_calculate_ball_top_right_scales(r))
    bottom_left = Nx.transpose(top_right)
    top_left = Nx.reverse(bottom_left, axes: [0])
    bottom_right = Nx.reverse(top_right, axes: [0])

    Nx.broadcast(0.0, {r * 2, r * 2})
    |> Nx.put_slice([0, 0], top_left)
    |> Nx.put_slice([0, r], top_right)
    |> Nx.put_slice([r, 0], bottom_left)
    |> Nx.put_slice([r, r], bottom_right)
  end

  def naive_calculate_ball_top_right_scales(8) do
    [
      [0.9729, 0.8469, 0.5867, 0.1844, 0.0, 0.0, 0.0, 0.0],
      [1.0, 1.0, 1.0, 0.9944, 0.5968, 0.0337, 0.0, 0.0],
      [1.0, 1.0, 1.0, 1.0, 1.0, 0.7527, 0.0337, 0.0],
      [1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 0.5968, 0.0],
      [1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 0.9944, 0.1844],
      [1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 0.5867],
      [1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 0.8469],
      [1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 0.9729]
    ]
  end

  def naive_calculate_ball_top_right_scales(n) do
    samples = 100
    ranges = Enum.map(1..n, &(&1 * samples))

    Enum.map(ranges, fn y_range -> Enum.map(ranges, fn x_range -> {x_range, y_range} end) end)
    |> Enum.reverse()
    |> Enum.map(fn row ->
      Enum.map(row, fn {x, y} ->
        calculate_one_box({x, y}, samples, n * samples)
      end)
    end)
  end

  def calculate_one_box({max_x, max_y}, n, r) do
    xs = (max_x - (n - 1))..max_x
    ys = (max_y - (n - 1))..max_y

    inside_count =
      Enum.map(xs, fn x ->
        Enum.reduce(ys, 0, fn y, acc ->
          if outside?(x, y, r) do
            acc
          else
            acc + 1
          end
        end)
      end)
      |> Enum.sum()

    inside_count / (n * n)
  end

  defp outside?(x, y, r) do
    x * x + y * y > r * r
  end
end
