defmodule PomodoroAppBot.Commands do
  def global(channel_user, command, sender) do
    case command do
      "pomotime" ->
        PomodoroAppBot.Bot.say(
          sender,
          "@#{sender} Pomo session time is currently set to #{channel_user.pomo_time} minutes."
        )

      "pomobreak" ->
        PomodoroAppBot.Bot.say(sender, "@#{sender} Pomo break time is #{channel_user.break_time} minutes.")
    end
  end
end
