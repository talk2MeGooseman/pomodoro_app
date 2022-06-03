defmodule PomodoroAppBot.Commands.Streamer do
  require Logger
  alias PomodoroApp.Pomos
  alias PomodoroApp.Accounts
  alias PomodoroApp.Accounts.User
  alias PomodoroAppBot.{Bot, PomoManagement}
  alias PomodoroAppBot.Commands.Global

  @commands [
    "!pomo start - starts a pomo session.",
    "!pomo end - ends a pomo session.",
    "!pomo break - Get the pomo break time.",
    "!pomo break <breaktime> - sets the break time.",
    "!pomo time - Get the pomo session time.",
    "!pomo time <pomotime> - sets the pomo time.",
    "!pomo stats - shows your pomo stats.",
    "!pomo today - shows your pomo stats for past 24 hours."
  ]

  def command(%User{} = channel_user, action, sender) do
    case action do
      "pomo start" ->
        if Pomos.pomo_active_for?(channel_user) do
          maybe_say(channel_user, "You already have a pomo running!")
        else
          PomoManagement.start_session(channel_user, sender)
        end

      "pomo end" ->
        case Pomos.get_active_pomo_for(channel_user.id) do
          nil ->
            maybe_say(
              channel_user,
              "There is no active pomo, '!pomo start' to begin the next one."
            )

          pomo_session ->
            PomoManagement.end_session(pomo_session, sender)
        end

      "pomo break" ->
        maybe_say(channel_user, "Pomo break time is set to #{channel_user.break_time} minutes.")

      "pomo break " <> breaktime ->
        case Integer.parse(breaktime) do
          :error ->
            maybe_say(channel_user, "Invalid break time provided.")

          _ ->
            case Accounts.update_user_break_time(channel_user, breaktime) do
              {:error, _} ->
                maybe_say(channel_user, "Error updating break time.")

              {:ok, channel_user} ->
                maybe_say(
                  channel_user,
                  "Break time updated to #{channel_user.break_time} minutes."
                )
            end
        end

      "pomo time" ->
        maybe_say(channel_user, "Pomo session time is set to #{channel_user.pomo_time} minutes.")

      "pomo time " <> pomotime ->
        case Integer.parse(pomotime) do
          :error ->
            maybe_say(channel_user, "Invalid pomo time provided.")

          _ ->
            PomoManagement.update_timer(channel_user, pomotime)
        end

      "pomo help" ->
        maybe_say(
          channel_user,
          "@#{sender} #{Enum.join(@commands, " ")}"
        )

      _ ->
        Global.command(channel_user, action, sender)
    end
  end

  def maybe_say(channel_user, message) do
    if !channel_user.mute do
      Bot.say(
        String.downcase(channel_user.username),
        message
      )
    end
  end
end
