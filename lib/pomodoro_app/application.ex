defmodule PomodoroApp.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    [bot_config]= Application.fetch_env!(:pomodoro_app, :bots)

    children = [
      # Start the Ecto repository
      PomodoroApp.Repo,
      # Start the Telemetry supervisor
      PomodoroAppWeb.Telemetry,
      # Start the PubSub system
      {Phoenix.PubSub, name: PomodoroApp.PubSub},
      # Start the Endpoint (http/https)
      PomodoroAppWeb.Endpoint,
      # Start a worker by calling: PomodoroApp.Worker.start_link(arg)
      # {PomodoroApp.Worker, arg}
      {TMI.Supervisor, bot_config},
      {Oban, oban_config()}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: PomodoroApp.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    PomodoroAppWeb.Endpoint.config_change(changed, removed)
    :ok
  end

  defp oban_config do
    Application.fetch_env!(:pomodoro_app, Oban)
  end
end
