defmodule PomodoroApp.Repo do
  use Ecto.Repo,
    otp_app: :pomodoro_app,
    adapter: Ecto.Adapters.Postgres
end
