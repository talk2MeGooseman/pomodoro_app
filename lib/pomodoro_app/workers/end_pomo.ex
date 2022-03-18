defmodule PomodoroApp.Workers.EndPomo do
  use Oban.Worker, queue: :default

  require Logger

  alias PomodoroApp.Pomos
  alias PomodoroAppBot.{PomoManagement}

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"session_id" => session_id, "channel" => channel}}) do
    case Pomos.get_pomo_session_by_id(session_id) do
      %Pomos.PomoSession{active: true} = pomo_session ->
        PomoManagement.end_session(pomo_session, channel)
      _ ->
        Logger.debug("Pomo Session is no longer active")
    end

    :ok
  end
end
