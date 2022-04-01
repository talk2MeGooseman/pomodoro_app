defmodule PomodoroApp.Workers.JoinChat do
  use Oban.Worker, queue: :default

  require Logger

  alias PomodoroApp.Accounts
  alias PomodoroAppBot.Bot

  @impl Oban.Worker
  def perform(%Oban.Job{}) do
    connected_channels = PomodoroAppBot.Bot.list_channels()

    Accounts.get_all_missing_users(connected_channels)
    |> Enum.each(&join_and_confirm(&1.username))

    :ok
  end

  def join_and_confirm(username) when is_binary(username) do
    Bot.join(username)
  end
end
