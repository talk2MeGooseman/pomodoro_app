defmodule PomodoroApp.Workers.EndPomo do
  use Oban.Worker, queue: :default

  import Logger

  alias PomodoroApp.Pomos
  alias PomodoroAppBot.Bot

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"user_id" => user_id, "channel" => channel} = _args}) do
    case Pomos.get_active_pomo_for(user_id) do
      %Pomos.PomoSession{} = pomo_session ->
        # Need to check if the pomo should end based off of the time
        case Pomos.update_pomo_session(pomo_session, %{active: false}) do
          {:ok, _pomo_session} ->
            Bot.say(channel, "Pomodoro ended!")

          {:error, _error} ->
            Bot.say(channel, "Something went wrong!")
        end
      _ ->
        Logger.info("No active pomo session found for user #{user_id}. No nothing")
    end

    :ok
  end
end
