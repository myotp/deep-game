defmodule DeepGame.Examples.DemoBreakout do
  alias DeepGame.Game.Breakout
  alias DeepGame.Gym.BreakoutGym

  def run() do
    game = Breakout.new()
    game_loop(game, 60, random_action())
  end

  defp random_action() do
    Enum.random([:left, :stop, :right])
  end

  defp game_loop(game, 0, _) do
    game_loop(game, 60, random_action())
  end

  defp game_loop(game, n, action) do
    Process.sleep(16)
    game = Breakout.handle_input(game, action)
    maybe_show_game_heatmap(game)
    game_loop(game, n - 1, action)
  end

  defp maybe_show_game_heatmap(game) do
    if Enum.random(1..1000) < 10 do
      Task.start(fn ->
        IO.puts("-- screen --")

        BreakoutGym.get_observation(game)
        |> Nx.to_heatmap()
        |> IO.inspect()
      end)
    end
  end
end
