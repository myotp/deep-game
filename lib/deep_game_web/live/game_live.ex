defmodule DeepGameWeb.GameLive do
  use Phoenix.LiveView

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    socket =
      assign(socket,
        username: "test",
        game_state: :welcome,
        game: nil
      )

    {:ok, socket}
  end

  @impl Phoenix.LiveView
  def handle_event("keyup", %{"key" => " "}, socket) do
    if socket.assigns.game_state == :welcome do
      socket =
        assign(socket, game_state: :running)

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
end
