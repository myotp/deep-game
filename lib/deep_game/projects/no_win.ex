defmodule DeepGame.Projects.NoWin do
  # train and test model
  def run() do
    model = build_model()
    model_state = train_model(model)
    test_model(model, model_state)
  end

  def build_model() do
  end

  def train_model(model) do
    train_images = load_train_images()
    train_labels = load_train_labels()
    train_model(model, train_images, train_labels)
  end

  def train_model(_model, _train_images, _train_labels) do
  end

  def load_train_images() do
    []
  end

  def load_train_labels() do
    []
  end

  def test_model(_model, _params) do
  end

  #
  def generate_game_screens() do
  end
end
