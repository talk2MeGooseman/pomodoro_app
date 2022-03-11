defmodule PomodoroAppWeb.PageController do
  use PomodoroAppWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end
end
