defmodule DeepGameWeb.GameLive do
  use Phoenix.LiveView

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    {:ok, assign(socket, username: "test")}
  end
end
