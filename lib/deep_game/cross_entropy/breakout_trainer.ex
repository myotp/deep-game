defmodule DeepGame.CrossEntropy.BreakoutTrainer do
  alias DeepGame.CrossEntropy.BreakoutEnv

  def build_model() do
    Axon.input("input", shape: {nil, 6})
    |> Axon.dense(128, activation: :relu)
    |> Axon.dense(3, activation: :softmax)
  end

  def train_model(model) do
    {init_fn, _predict_fn} = Axon.build(model)
    # init_random_params = init_fn.(Nx.template({1, 6}, :f32), %{})
    loop_train(model, {nil, init_fn}, 3)
  end

  def loop_train(_model, {params, _}, 0) do
    {:done, params}
  end

  def loop_train(model, {params, init_fn}, n) do
    {observations, actions_groups} = gen_random_episode_with_params(model, params, init_fn)
    observations_t = Enum.map(observations, &Nx.tensor/1)

    actions_t =
      Enum.map(actions_groups, fn actions ->
        Enum.map(actions, fn action -> [action] end)
        |> Nx.tensor()
        |> Nx.equal(Nx.tensor([0, 1, 2]))
      end)

    updated_params = train_model(model, observations_t, actions_t)
    loop_train(model, {updated_params, init_fn}, n - 1)
  end

  def train_model(model, observations, actions) do
    model
    |> Axon.Loop.trainer(
      :categorical_cross_entropy,
      Polaris.Optimizers.adamw(learning_rate: 0.005)
    )
    |> Axon.Loop.run(Stream.zip(observations, actions), %{}, epochs: 1, compiler: EXLA)
  end

  # FIXME: temp fix to keep all tensors in the same shape
  defp keep_only_same_reward([{reward, _} | _] = l) do
    Enum.reject(l, fn {r, _} -> r != reward end)
  end

  def gen_random_episode_with_params(model, params, init_fn) do
    episode =
      1..100_000
      |> Enum.map(fn _ -> one_episode_with_params(model, params, init_fn) end)
      |> Enum.sort_by(fn {reward, _} -> reward end, :desc)
      |> keep_only_same_reward()
      |> Enum.take(100)

    episode
    |> Enum.map(fn {reward, _} -> reward end)
    |> IO.inspect(label: "Top 5 rewards: ")

    observations =
      Enum.map(episode, fn {_reward, steps} ->
        Enum.map(steps, fn {observations, _action, _reward} ->
          observations
        end)
      end)

    actions =
      Enum.map(episode, fn {_reward, steps} ->
        Enum.map(steps, fn {_observations, action, _reward} ->
          action
        end)
      end)

    {observations, actions}
  end

  # def gen_random_episode(_percentile) do
  #   1..10000
  #   |> Enum.map(fn _ -> random_episode() end)
  #   |> Enum.sort_by(fn {reward, _} -> reward end, :desc)
  #   |> Enum.map(fn {reward, _} -> reward end)
  #   |> Enum.take(100)
  # end

  def random_episode() do
    env = BreakoutEnv.reset()
    env = BreakoutEnv.move_ball_random(env)
    observations = BreakoutEnv.observations(env)
    gen_random_episode(env, observations, 0, [])
  end

  def one_episode_with_params(model, params, init_fn) do
    env = BreakoutEnv.reset()
    env = BreakoutEnv.move_ball_random(env)
    observations = BreakoutEnv.observations(env)

    params =
      case params do
        nil ->
          init_fn.(Nx.template({1, 6}, :f32), %{})

        _ ->
          params
      end

    one_episode_with_params(env, model, params, observations, 0, [])
  end

  defp one_episode_with_params(env, model, params, observations, total_reward, acc) do
    action = select_action(observations, model, params)
    {env, obs, reward, done?} = BreakoutEnv.step(env, action)
    acc = [{observations, action, reward} | acc]

    if done? do
      {total_reward, Enum.reverse(acc)}
    else
      one_episode_with_params(env, model, params, obs, total_reward + reward, acc)
    end
  end

  def select_action(observations, model, params) do
    obs_t = Nx.tensor([observations])

    Axon.predict(model, params, obs_t)
    |> Nx.squeeze()
    |> Nx.to_list()
    |> random_action()
  end

  defp gen_random_episode(env, observations, total_reward, acc) do
    action = select_action(observations)
    {env, obs, reward, done?} = BreakoutEnv.step(env, action)
    acc = [{observations, action, reward} | acc]

    if done? do
      {total_reward, Enum.reverse(acc)}
    else
      gen_random_episode(env, obs, total_reward + reward, acc)
    end
  end

  defp select_action(_) do
    Enum.random(BreakoutEnv.actions())
  end

  def random_action(action_probs) do
    score = :rand.uniform()
    random_action(score, action_probs, 0)
  end

  defp random_action(score, [h | t], n) do
    if h > score do
      n
    else
      random_action(score - h, t, n + 1)
    end
  end
end
