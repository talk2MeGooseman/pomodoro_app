defmodule PomodoroAppBot.Bot do
  use TMI

  require Logger
  alias PomodoroAppWeb.Presence
  alias PomodoroApp.{Accounts, Pomos}
  alias PomodoroAppBot.Commands

  @reminder_threshold_seconds 5 * 60

  @impl TMI.Handler
  def handle_message("!" <> command, sender, "#" <> sender) do
    channel_user = Accounts.get_user_by_username(sender)

    case command do
      "pomo" ->
        case Pomos.get_active_pomo_for(channel_user.id) do
          nil ->
            say(sender, "There isnt a pomo currently active.")

          pomo_session ->
            remaining_minutes = floor(calculate_seconds_remaining(pomo_session) / 60)

            say(
              sender,
              "There is #{remaining_minutes} minutes remaining in the pomo, you got this."
            )
        end

      "pomostart" ->
        if Pomos.pomo_active_for?(channel_user) do
          say(sender, "You already have a pomodoro running!")
        else
          start_pomo_session(channel_user, sender)
        end

      "pomoend" ->
        case Pomos.get_active_pomo_for(channel_user.id) do
          nil ->
            say(sender, "You have no active pomos.")

          pomo_session ->
            case Pomos.update_pomo_session(pomo_session, %{active: false}) do
              {:ok, _pomo_session} ->
                Presence.clean_up_pomo_presence(sender)

                say(sender, "Pomodoro ended!")

              {:error, _error} ->
                say(sender, "Uh oh, I had a problem ending current pomo.")
            end
        end

      "pomobreak " <> breaktime ->
        case Integer.parse(breaktime) do
          :error ->
            say(sender, "Invalid break time provided.")

          _ ->
            case Accounts.update_user_break_time(channel_user, breaktime) do
              {:error, _} ->
                say(sender, "Error updating break time.")

              {:ok, channel_user} ->
                say(sender, "Break time updated to #{channel_user.break_time} minutes.")
            end
        end

      "pomotime " <> pomotime ->
        case Integer.parse(pomotime) do
          :error ->
            say(sender, "Invalid pomo time provided.")

          _ ->
            case Accounts.update_user_pomo_time(channel_user, pomotime) do
              {:error, _error} ->
                say(sender, "Error updating pomo time.")

              {:ok, channel_user} ->
                say(sender, "Pomo time updated to #{channel_user.pomo_time} minutes.")
            end
        end

      _ ->
        Commands.global(channel_user, command, sender)
    end
  end

  def handle_message("!" <> command, sender, "#" <> channel) do
    Accounts.get_user_by_username(channel)
    |> Commands.global(command, sender)
  end

  def handle_message(_message, sender, "#" <> channel) do
    channel_user = Accounts.get_user_by_username(channel)

    if Pomos.pomo_active_for?(channel_user) do
      maybe_send_pomo_active_reminder(channel_user, sender)
    end
  end

  defp maybe_send_pomo_active_reminder(channel, sender) do
    case Presence.get_by_key("channel:#{channel}", sender) do
      [] ->
        send_pomo_active_reminder(channel, sender)

      %{
        metas: [
          %{
            reminded_at: reminded_at
          }
        ]
      } ->
        if remind_user?(reminded_at) do
          send_pomo_active_reminder(channel, sender)
        end
    end
  end

  defp remind_user?(reminded_at) do
    NaiveDateTime.diff(NaiveDateTime.utc_now(), reminded_at) >
      @reminder_threshold_seconds
  end

  defp send_pomo_active_reminder(channel, sender) do
    Presence.track_pomo_presence(channel, sender)
    say(channel, "Shhhh @#{sender}, it's time to focus!")
  end

  defp start_pomo_session(user, channel) do
    Pomos.build_pomo_session_attrs(user)
    |> Pomos.create_pomo_session()
    |> case do
      {:ok, pomo_session} ->
        seconds_delay = calculate_seconds_remaining(pomo_session)
        enqueue_pomo_timer(user.id, channel, seconds_delay)

        say(
          channel,
          "Pomodoro started, time to focus for the next #{pomo_session.pomo_time} minutes!"
        )

      {:error, _error} ->
        say(channel, "Opps, something went wrong starting the pomo session!")
    end
  end

  defp calculate_seconds_remaining(%Pomos.PomoSession{end: end_on}) do
    NaiveDateTime.diff(end_on, NaiveDateTime.utc_now())
  end

  defp enqueue_pomo_timer(user_id, channel, seconds_delay) do
    %{user_id: user_id, channel: channel}
    |> PomodoroApp.Workers.EndPomo.new(schedule_in: seconds_delay)
    |> Oban.insert()
  end
end
