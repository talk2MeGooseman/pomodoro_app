defmodule PomodoroApp.Workers.BreakTimeOver do
  use Oban.Worker, queue: :default

  require Logger

  alias PomodoroApp.Pomos
  alias PomodoroApp.Pomos.PomoSession
  alias PomodoroAppBot.Bot

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"user_id" => user_id, "channel" => channel}}) do
    case Pomos.get_active_pomo_for(user_id) do
      %PomoSession{} ->
        Logger.debug("Pomo Session has been started, do nothing.")

      nil ->
        Bot.say(channel, "@#{channel} psssst beaktime is over, time to get busy!")
    end

    :ok
  end
end
