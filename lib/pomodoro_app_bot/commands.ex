defmodule PomodoroAppBot.Commands do
  require Logger
  alias PomodoroApp.Pomos
  alias PomodoroAppBot.{Bot, PomoManagement}

  def global(channel_user, command, sender) do
    case command do
      "pomo" ->
        case Pomos.get_active_pomo_for(channel_user.id) do
          nil ->
            Bot.say(channel_user.username, "There isnt a pomo currently active.")

          pomo_session ->
            remaining_minutes =
              floor(PomoManagement.calculate_seconds_remaining(pomo_session) / 60)

            Bot.say(
              channel_user.username,
              "There is #{remaining_minutes} minutes remaining in the pomo, you got this."
            )
        end

      "pomo time" ->
        Bot.say(
          channel_user.username,
          "@#{sender} Pomo session time is currently set to #{channel_user.pomo_time} minutes."
        )

      "pomo break" ->
        Bot.say(
          channel_user.username,
          "@#{sender} Pomo break time is #{channel_user.break_time} minutes."
        )

      "pomo join" ->
        case Pomos.get_active_pomo_for(channel_user.id) do
          nil ->
            Bot.say(channel_user.username, "There isnt a pomo currently active.")

          pomo_session ->
            with {:ok, member} <- Pomos.find_or_create_member(sender),
                 attrs <- Pomos.build_pomo_session_member_attrs(member, pomo_session),
                 {:ok, _session_member} <- Pomos.create_pomo_session_member(attrs) do
              Bot.say(
                channel_user.username,
                "@#{sender} thanks for joining in, now it's time to focus."
              )
            else
              _ -> Bot.say(channel_user.username, "Error joining pomo.")
            end
        end

      _ ->
        Logger.warn("Unknown command: #{command}")
    end
  rescue
    _ -> Logger.warn("Error occurred")
  end
end
