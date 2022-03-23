defmodule PomodoroAppBot.PomoManagement do
  require Logger

  alias PomodoroApp.{Accounts, Pomos}
  alias PomodoroApp.Pomos.PomoSession
  alias PomodoroAppWeb.Presence
  alias PomodoroAppBot.Bot

  def start_session(user, channel) do
    Pomos.build_pomo_session_attrs(user)
    |> Pomos.create_pomo_session()
    |> tap(fn _ -> Presence.clean_up_pomo_presence(channel) end)
    |> case do
      {:ok, pomo_session} ->
        seconds_delay = calculate_seconds_remaining(pomo_session)
        enqueue_pomo_timer(pomo_session.id, channel, seconds_delay)

        Bot.say(
          channel,
          "Let's do this, time to focus for the next #{pomo_session.pomo_time} minutes!"
        )

        Bot.say(
          channel,
          "If you would like to join in and track stats use '!pomo join' or '!pomo help' for more info."
        )

      {:error, _error} ->
        Bot.say(channel, "Opps, something went wrong starting the pomo session.")
    end
  end

  def update_timer(channel_user, pomotime) do
    case Accounts.update_user_pomo_time(channel_user, pomotime) do
      {:error, _error} ->
        Bot.say(
          channel_user.username,
          "Uh oh, I couldn't update the pomo time. Try again in a little bit."
        )

      {:ok, channel_user} ->
        Bot.say(channel_user.username, "Pomo time updated to #{channel_user.pomo_time} minutes.")
    end
  end

  def end_session(%PomoSession{} = pomo_session, channel) do
    case Pomos.update_pomo_session(pomo_session, %{active: false}) do
      {:ok, _pomo_session} ->
        Bot.say(channel, "Pomo has ended! Great job. Use '!pomo today' to see your stats.")

      {:error, _error} ->
        Bot.say(channel, "Uh oh, I had a problem ending the current pomo.")
    end
  end

  def calculate_seconds_remaining(%Pomos.PomoSession{end: end_on}) do
    NaiveDateTime.diff(end_on, NaiveDateTime.utc_now())
  end

  defp enqueue_pomo_timer(session_id, channel, seconds_delay) do
    %{session_id: session_id, channel: channel}
    |> PomodoroApp.Workers.EndPomo.new(schedule_in: seconds_delay)
    |> Oban.insert()
  end
end
