defmodule PomodoroApp.Workers.JoinChat do
  use Oban.Worker, queue: :default

  require Logger

  alias PomodoroApp.Accounts
  alias PomodoroAppBot.Bot

  @impl Oban.Worker
  def perform(%Oban.Job{}) do
    connected_channels = PomodoroAppBot.Bot.list_channels()
    Accounts.get_all_missing_users(connected_channels)
    |> Enum.each(&Bot.join(&1.username))

    :ok
  end
end
