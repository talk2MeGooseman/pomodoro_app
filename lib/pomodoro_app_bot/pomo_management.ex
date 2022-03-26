defmodule PomodoroAppBot.PomoManagement do
  require Logger

  @reminder_threshold_seconds 10 * 60
  @allow_list ["streamelements", "talk2megooseman", "gooseman_bot"]

  alias PomodoroApp.{Accounts, Pomos, Repo}
  alias PomodoroApp.Accounts.User
  alias PomodoroApp.Pomos.PomoSession
  alias PomodoroAppWeb.Presence
  alias PomodoroAppBot.Bot

  def start_session(user, channel) do
    Pomos.build_pomo_session_attrs(user)
    |> Pomos.create_pomo_session()
    |> tap(fn _ -> Presence.clean_up_pomo_presence(channel) end)
    |> case do
      {:ok, pomo_session} ->
        enqueue_pomo_timer(pomo_session.id, channel, pomo_session.end)

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

  def join_session(%PomoSession{} = pomo_session, channel, sender, goal \\ nil)
      when is_binary(channel) and is_binary(sender) do
    with {:ok, member} <- Pomos.find_or_create_member(sender),
         attrs <- Pomos.build_pomo_session_member_attrs(member, pomo_session, goal),
         {:ok, _session_member} <- Pomos.create_pomo_session_member(attrs) do
      Bot.say(
        channel,
        "@#{sender} thanks for joining in, now it's time to focus."
      )
    else
      _ -> Bot.say(channel, "Error joining pomo.")
    end
  end

  def handle_message(channel, sender) when is_binary(channel) and is_binary(sender) do
    with %User{} = channel_user <- Accounts.get_user_by_username(channel),
         true <- Pomos.pomo_active_for?(channel_user) do
      maybe_send_pomo_active_reminder(channel_user, sender)
    end
  end

  def calculate_seconds_remaining(%Pomos.PomoSession{end: end_on}) do
    NaiveDateTime.diff(end_on, NaiveDateTime.utc_now())
  end

  defp enqueue_pomo_timer(session_id, channel, %DateTime{} = end_on) do
    %{session_id: session_id, channel: channel}
    |> PomodoroApp.Workers.EndPomo.new(scheduled_at: end_on)
    |> Oban.insert()
  end

  defp enqueue_pomo_break_time_reminder(user_id, channel, %DateTime{} = scheduled_at) do
    %{user_id: user_id, channel: channel}
    |> PomodoroApp.Workers.BreakTimeOver.new(scheduled_at: scheduled_at)
    |> Oban.insert()
  end

  defp maybe_send_pomo_active_reminder(channel_user, sender) do
    case Presence.get_by_key("channel:#{channel_user.username}", sender) do
      [] ->
        send_pomo_active_reminder(channel_user.username, sender)

      %{
        metas: [
          %{
            reminded_at: reminded_at
          }
        ]
      } ->
        if remind_user?(reminded_at) do
          send_pomo_active_reminder(channel_user.username, sender)
        end
    end
  end

  defp remind_user?(reminded_at) do
    DateTime.diff(DateTime.utc_now(), reminded_at) >
      @reminder_threshold_seconds
  end

  defp send_pomo_active_reminder(_channel, sender) when is_binary(sender) and sender in @allow_list, do: nil

  defp send_pomo_active_reminder(channel, sender)
       when is_binary(channel) and is_binary(sender) and sender not in @allow_list do
    Presence.track_pomo_presence(channel, sender)
    Bot.say(channel, "Shhhh @#{sender}, it's time to focus. Use '!pomo info' to get more information.")
  end
end
