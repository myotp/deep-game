defmodule DeepGame.Gym.BreakoutEnv do
  alias DeepGame.Game.Breakout

  defstruct [
    :game,
    :obs_mod,
    :game_loop_interval
  ]

  @action_stop 0
  @action_left 1
  @action_right 2

  @game_loop_inteval 16

  # DRL Environment APIs
  def new(opts \\ []) do
    opts =
      Keyword.validate!(opts,
        obs_mod: DeepGame.Gym.BreakoutGuiObs,
        game_loop_inteval: @game_loop_inteval
      )

    %__MODULE__{
      game: Breakout.new(),
      obs_mod: opts[:obs_mod],
      game_loop_interval: opts[:game_loop_inteval]
    }
  end

  def reset(env) do
    game = Breakout.new()
    %__MODULE__{env | game: game}
  end

  def get_actions(_env) do
    [@action_stop, @action_left, @action_right]
  end

  def is_done?(env) do
    game_done?(env.game)
  end

  def step(env, action) do
    input = action_to_input(action)
    game = game_update(env.game, input, env.game_loop_inteval)
    new_env = %__MODULE__{env | game: game}
    observation = env.obs_mod.game_to_observation(game)
    reward = 1
    {new_env, reward, game_done?(game)}
  end

  defp action_to_input(@action_stop), do: :stop
  defp action_to_input(@action_left), do: :left
  defp action_to_input(@action_right), do: :right

  defp game_update(game, input, game_loop_interval) do
    game
    |> Breakout.handle_input(input)
    |> Breakout.update(game_loop_interval)
  end

  defp game_done?(game) do
    game.game_state != :running
  end

  def dirty_set!(env, attrs) do
    env
  end
end
