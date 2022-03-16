defmodule PomodoroAppWeb.UserLiveAuth do
  import Phoenix.LiveView

  def on_mount(:default, params, %{ "user_token" => user_token }, socket) do
    socket = assign_new(socket, :current_user, fn ->
      PomodoroAppWeb.UserAuth.fetch_token_current_user(user_token)
    end)

    if socket.assigns.current_user do
      {:cont, socket}
    else
      {:halt, redirect(socket, to: "/")}
    end
  end

  def on_mount(:default, params, session, socket) do
    {:halt, redirect(socket, to: "/")}
  end
end
