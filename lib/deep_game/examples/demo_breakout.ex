defmodule DeepGame.Examples.DemoBreakout do
  alias DeepGame.Game.Breakout
  alias DeepGame.Gym.BreakoutEnv

  def run(0) do
    :done
  end

  def run(n) do
    game = Breakout.new()
    game_loop(game, 60, random_action())
    run(n - 1)
  end

  defp random_action() do
    Enum.random([:left, :stop, :right])
  end

  defp game_loop(game, 0, _) do
    game_loop(game, 60, random_action())
  end

  defp game_loop(game, n, action) do
    Process.sleep(16)

    game =
      game
      |> Breakout.handle_input(action)
      |> Breakout.update(16)

    render_info = Breakout.render_info(game)

    case render_info.game_state do
      :running ->
        maybe_show_game_heatmap(game, n)
        game_loop(game, n - 1, action)

      other_state ->
        IO.inspect(other_state, label: "Game finished")
    end
  end

  defp maybe_show_game_heatmap(game, 33) do
    IO.puts("-- screen --")

    BreakoutEnv.get_observation(game)
    |> Nx.to_heatmap()
    |> IO.inspect()
  end

  defp maybe_show_game_heatmap(_, _), do: :ok
end
