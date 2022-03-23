defmodule PomodoroAppBot.Bot do
  use TMI

  require Logger
  alias PomodoroAppWeb.Presence
  alias PomodoroApp.{Accounts, Pomos}
  alias PomodoroApp.Accounts.User
  alias PomodoroAppBot.Commands.{Global, Streamer}

  @reminder_threshold_seconds 5 * 60
  @allow_list ["streamelements", "talk2megooseman", "gooseman_bot"]

  @impl TMI.Handler
  def handle_message("!" <> command, sender, "#" <> sender) do
    channel_user = Accounts.get_user_by_username(sender)
    Streamer.command(channel_user, command, sender)
  rescue
    _ -> Logger.warn("Error occurred")
  end

  def handle_message("!" <> command, sender, "#" <> channel) do
    channel_user = Accounts.get_user_by_username(channel)
    Global.command(channel_user, command, sender)
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
    DateTime.diff(DateTime.utc_now(), reminded_at) >
      @reminder_threshold_seconds
  end

  defp send_pomo_active_reminder(_channel, sender) when sender in @allow_list, do: nil

  defp send_pomo_active_reminder(channel, sender)
       when is_binary(channel) and is_binary(sender) and sender not in @allow_list do
    Presence.track_pomo_presence(channel, sender)
    say(channel, "Shhhh @#{sender}, it's time to focus. Use '!pomo info' to get more information.")
  end
end
