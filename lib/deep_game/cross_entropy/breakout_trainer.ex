defmodule DeepGame.CrossEntropy.BreakoutTrainer do
  alias DeepGame.CrossEntropy.BreakoutEnv

  def build_model() do
    Axon.input("input", shape: {nil, 5})
    |> Axon.dense(32, activation: :relu)
    # No softmax here
    |> Axon.dense(3, activation: :softmax)
  end

  def train_model(model) do
    {init_fn, _predict_fn} = Axon.build(model)
    # init_random_params = init_fn.(Nx.template({1, 5}, :f32), %{})
    loop_train(model, {nil, init_fn}, 20)
  end

  defp test_params(_model, nil) do
    :ok
  end

  defp test_params(model, params) do
    1..100
    |> Enum.map(fn _ ->
      {r, _} = one_episode_with_params(model, params, nil)
      r
    end)
    |> Enum.sort(:desc)
    |> IO.inspect(label: "===== TEST REWARDS")
  end

  defp loop_train(_model, {params, _}, 0) do
    {:done, params}
  end

  defp loop_train(model, {params, init_fn}, n) do
    test_params(model, params)
    {observations, actions_groups} = gen_random_episode_with_params(model, params, init_fn)

    Enum.map(observations, &Enum.count/1)
    |> IO.inspect(label: "Each observations size")

    flat_observations = Enum.concat(observations)
    observations_t = flat_observations |> Nx.tensor()
    flat_actions = Enum.concat(actions_groups)
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
      {updated_params, init_fn},
      n - 1
    )
  end

  defp train_model(model, observations, actions) do
    # loss_fn = fn y_true, y_pred ->
    #   Axon.Losses.categorical_cross_entropy(y_true, y_pred, sparse: true)
    # end

    model
    # |> Axon.activation(:softmax)
    |> Axon.Loop.trainer(:categorical_cross_entropy, Polaris.Optimizers.adam(learning_rate: 0.01))
    |> Axon.Loop.run(Stream.zip(observations, actions), %{}, epochs: 10, compiler: EXLA)
  end

  defp gen_random_episode_with_params(model, params, init_fn) do
    episode =
      1..5000
      |> Enum.map(fn _ -> one_episode_with_params(model, params, init_fn) end)
      |> Enum.sort_by(fn {reward, _} -> reward end, :desc)
      |> Enum.take(300)

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

  defp one_episode_with_params(model, params, init_fn) do
    env = BreakoutEnv.reset()
    env = BreakoutEnv.move_ball_random(env)
    observations = BreakoutEnv.observations(env)

    params =
      case params do
        nil ->
          init_fn.(Nx.template({1, 5}, :f32), %{})

        _ ->
          params
      end

    one_episode_with_params(env, model, params, observations, 0, [])
  end

  defp one_episode_with_params(env, model, params, observations, total_reward, acc) do
    action = select_action(observations, model, params)
    {env, obs, reward, done?} = BreakoutEnv.step(env, action)

    acc =
      case observations do
        [_, speed_y, _, _, _] when speed_y > 0 ->
          acc

        [_, speed_y, _ball_x, _, _paddle_x] when speed_y < 0 ->
          # last_reward = ((1 - abs(ball_x - paddle_x)) * 100) ** 2
          [{observations, action, reward} | acc]
      end

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
    # |> Axon.Activations.softmax()
    |> Nx.to_list()
    |> random_action()
  end

  defp random_action(action_probs) do
    score = :rand.uniform()
    random_action(score, action_probs, 0)
  end

  defp random_action(_score, [_], n) do
    n
  end

  defp random_action(score, [h | t], n) do
    if h > score do
      n
    else
      random_action(score - h, t, n + 1)
    end
  end
end
