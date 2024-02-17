defmodule DeepGame.CrossEntropy.BreakoutTrainer do
  alias DeepGame.CrossEntropy.BreakoutEnv

  def build_model() do
    Axon.input("input", shape: {nil, 6})
    |> Axon.dense(256, activation: :relu)
    |> Axon.dropout(rate: 0.2)
    |> Axon.dense(3, activation: :softmax)
  end

  def train_model(model) do
    {init_fn, _predict_fn} = Axon.build(model)
    init_random_params = init_fn.(Nx.template({1, 6}, :f32), %{})
    loop_train(model, init_random_params, 20, {[], []})
  end

  defp test_params(model, params) do
    1..100
    |> Enum.map(fn _ ->
      {r, _} = one_episode_with_params(model, params)
      r
    end)
    |> Enum.sort(:desc)
    |> IO.inspect(label: "===== TEST REWARDS")
  end

  defp loop_train(_model, params, 0, _) do
    {:done, params}
  end

  defp loop_train(model, params, n, {great_obs, great_actions}) do
    test_params(model, params)
    {observations, actions_groups} = gen_random_episode_with_params(model, params)

    new_good_obs = hd(observations)
    new_good_actions = hd(actions_groups)

    Enum.map(observations, &Enum.count/1)
    |> IO.inspect(label: "Each observations size")

    flat_observations = Enum.concat(observations) ++ great_obs
    observations_t = flat_observations |> Nx.tensor()
    flat_actions = Enum.concat(actions_groups) ++ great_actions
    actions_size = Enum.count(flat_actions)

    actions_t =
      flat_actions
      |> Nx.tensor()
      |> Nx.reshape({actions_size, 1})
      |> Nx.equal(Nx.tensor([0, 1, 2]))

    observations_t |> Nx.shape() |> IO.inspect(label: "TT SHAPE")
    actions_t |> Nx.shape() |> IO.inspect(label: "ACTIONS SHAPE")

    batched_observations = Nx.to_batched(observations_t, 32)
    batched_actions = Nx.to_batched(actions_t, 32)

    updated_params = train_model(model, batched_observations, batched_actions)

    loop_train(
      model,
      updated_params,
      n - 1,
      {great_obs ++ new_good_obs, great_actions ++ new_good_actions}
    )
  end

  defp train_model(model, observations, actions) do
    model
    |> Axon.Loop.trainer(
      :categorical_cross_entropy,
      Polaris.Optimizers.adamw(learning_rate: 0.001)
    )
    |> Axon.Loop.run(Stream.zip(observations, actions), %{}, epochs: 10, compiler: EXLA)
  end

  defp gen_random_episode_with_params(model, params) do
    episode =
      1..2000
      |> Enum.map(fn _ -> one_episode_with_params(model, params) end)
      |> Enum.sort_by(fn {reward, _} -> reward end, :desc)
      |> Enum.take(10)

    episode
    |> Enum.map(fn {reward, _} -> reward end)
    |> IO.inspect(label: "Test rewards")

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

  defp one_episode_with_params(model, params) do
    env = BreakoutEnv.reset()
    env = BreakoutEnv.move_ball_random(env)
    observations = BreakoutEnv.observations(env)
    one_episode_with_params(env, model, params, observations, 0, [])
  end

  defp one_episode_with_params(env, model, params, observations, total_reward, acc) do
    action = select_action(observations, model, params)
    {env, obs, reward, done?} = BreakoutEnv.step(env, action)

    acc =
      case observations do
        [_, speed_y, _, _, _, _] when speed_y > 0 ->
          acc

        [_, speed_y, ball_x, _, paddle_x, _] when speed_y < 0 ->
          last_punishment = abs(ball_x - paddle_x) * 20
          [{observations, action, reward + last_punishment} | acc]
      end

    if done? do
      {total_reward, Enum.reverse(acc)}
    else
      one_episode_with_params(env, model, params, obs, total_reward + reward, acc)
    end
  end

  defp select_action(observations, model, params) do
    obs_t = Nx.tensor([observations])

    Axon.predict(model, params, obs_t)
    |> Nx.squeeze()
    |> Nx.to_list()
    |> random_action()
  end

  defp random_action(action_probs) do
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
