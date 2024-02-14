defmodule DeepGameWeb.GameLive do
  use Phoenix.LiveView

  alias DeepGame.Core.Game

  @game_loop_interval 100

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    socket =
      assign(socket,
        username: "test",
        game_state: :welcome,
        game: nil,
        timer_ref: nil
      )

    {:ok, socket}
  end

  @impl Phoenix.LiveView
  def handle_event("keyup", %{"key" => " "}, socket) do
    if socket.assigns.game_state == :welcome do
      game = Game.new()
      {:ok, ref} = :timer.send_interval(@game_loop_interval, self(), :tick)

      socket =
        assign(socket,
          game_state: :running,
          game: game,
          timer_ref: ref
        )

      {:noreply, socket}
    else
      IO.puts("Game already started")
      {:noreply, socket}
    end
  end

  def handle_event(event, _unsigned_params, socket) do
    IO.inspect(event, label: "KEY EVENT")
    {:noreply, socket}
  end

  @impl Phoenix.LiveView
  # Actuall GameLoop
  def handle_info(:tick, socket) do
    game = Game.update(socket.assigns.game, @game_loop_interval)
    render_info = Game.render(game)
    socket = render(socket, render_info)
    {:noreply, socket}
  end

  defp render(socket, _render_info) do
    socket
  end
end
