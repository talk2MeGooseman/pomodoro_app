defmodule PomodoroAppBot.Bot do
  use TMI

  require Logger
  alias PomodoroAppWeb.Presence
  alias PomodoroApp.{Accounts, Pomos}
  alias PomodoroApp.Accounts.User
  alias PomodoroAppBot.{Commands, PomoManagement}

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
            remaining_minutes =
              floor(PomoManagement.calculate_seconds_remaining(pomo_session) / 60)

            say(
              sender,
              "There is #{remaining_minutes} minutes remaining in the pomo, you got this."
            )
        end

      "pomostart" ->
        if Pomos.pomo_active_for?(channel_user) do
          say(sender, "You already have a pomodoro running!")
        else
          PomoManagement.start_session(channel_user, sender)
        end

      "pomoend" ->
        case Pomos.get_active_pomo_for(channel_user.id) do
          nil ->
            say(sender, "There is no active pomo, !pomostart to begin the next one.")

          pomo_session ->
            PomoManagement.end_session(pomo_session, sender)
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
            PomoManagement.update_timer(channel_user, pomotime)
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
    with %User{} = channel_user <- Accounts.get_user_by_username(channel),
         true <- Pomos.pomo_active_for?(channel_user) do
      maybe_send_pomo_active_reminder(channel_user, sender)
    end
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
    NaiveDateTime.diff(NaiveDateTime.utc_now(), reminded_at) >
      @reminder_threshold_seconds
  end

  defp send_pomo_active_reminder(channel, sender) when is_binary(channel) and is_binary(sender) do
    Presence.track_pomo_presence(channel, sender)
    say(channel, "Shhhh @#{sender}, it's time to focus!")
  end
end
