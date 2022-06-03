defmodule PomodoroAppBot.Bot do
  use TMI

  require Logger

  alias PomodoroApp.Accounts
  alias PomodoroAppBot.PomoManagement
  alias PomodoroAppBot.Commands.{Global, Streamer}

  @impl TMI.Handler
  # Channel Commands
  def handle_message("!" <> command, sender, "#" <> sender) do
    channel_user = Accounts.get_user_by_username(sender)
    Streamer.command(channel_user, command, sender)
  rescue
    _ -> Logger.warn("Error occurred")
  end

  # Viewer Commands
  def handle_message("!" <> command, sender, "#" <> channel) do
    channel_user = Accounts.get_user_by_username(channel)
    if !channel_user.mute do
      Global.command(channel_user, command, sender)
    end
  end

  # Standard Chat Message
  def handle_message(_message, sender, "#" <> channel) when sender == channel, do: nil
  def handle_message(_message, sender, "#" <> channel) do
    PomoManagement.handle_message(channel, sender)
  end
end
