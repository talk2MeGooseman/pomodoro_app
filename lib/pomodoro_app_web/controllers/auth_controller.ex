defmodule PomodoroAppWeb.AuthController do
  use PomodoroAppWeb, :controller

  alias PomodoroApp.Accounts
  alias PomodoroAppWeb.UserAuth

  def callback(%{assigns: %{ueberauth_failure: _fails}} = conn, _params) do
    conn
    |> put_flash(:error, "Failed to authenticate.")
    |> redirect(to: "/")
  end

  def callback(%{assigns: %{ueberauth_auth: auth}} = conn, _params) do
    %{extra: %{raw_info: %{user: user}}, credentials: creds} = auth
    [user_info] = user["data"]

    creds = Map.from_struct(creds)

    case Accounts.find_or_register_user_with_oauth(user_info, creds) do
      {:ok, user} ->
        conn
        |> put_flash(:info, "Successfully authenticated.")
        |> UserAuth.log_in_user(user)
        |> redirect(to: "/")
      _ ->
        conn
        |> put_flash(:error, "Erorr authenticating.")
        |> redirect(to: "/")
    end
  end
end
