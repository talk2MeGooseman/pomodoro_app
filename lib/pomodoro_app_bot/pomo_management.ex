defmodule PomodoroAppBot.PomoManagement do
  require Logger

  alias PomodoroApp.{Accounts, Pomos, Repo}
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
      {:ok, updated_pomo_session} ->
        updated_pomo_session = Repo.preload(updated_pomo_session, :user)
        user = updated_pomo_session.user
        scheduled_at = DateTime.add(DateTime.utc_now(), user.break_time * 60)

        enqueue_pomo_break_time_reminder(user.id, channel, scheduled_at)
        Bot.say(channel, "Pomo has ended! Great job. Use '!pomo today' to see your stats.")

      {:error, _error} ->
        Bot.say(channel, "Uh oh, I had a problem ending the current pomo.")
    end
  end

  def join_session(%PomoSession{} = pomo_session, channel, sender)
      when is_binary(channel) and is_binary(sender) do
    with {:ok, member} <- Pomos.find_or_create_member(sender),
         attrs <- Pomos.build_pomo_session_member_attrs(member, pomo_session),
         {:ok, _session_member} <- Pomos.create_pomo_session_member(attrs) do
      Bot.say(
        channel,
        "@#{sender} thanks for joining in, now it's time to focus."
      )
    else
      _ -> Bot.say(channel, "Error joining pomo.")
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

  defp enqueue_pomo_break_time_reminder(user_id, channel, %DateTime{} = scheduled_at) do
    %{user_id: user_id, channel: channel}
    |> PomodoroApp.Workers.BreakTimeOver.new(scheduled_at: scheduled_at)
    |> Oban.insert()
  end
end
