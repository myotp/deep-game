defmodule DeepGameWeb.Router do
  use DeepGameWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {DeepGameWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", DeepGameWeb do
    pipe_through :browser

    live "/", GameLive
  end

  # Other scopes may use custom stacks.
  # scope "/api", DeepGameWeb do
  #   pipe_through :api
  # end
end
