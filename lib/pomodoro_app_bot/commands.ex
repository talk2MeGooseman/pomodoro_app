defmodule PomodoroAppBot.Commands do
  require Logger
  alias PomodoroApp.Pomos
  alias PomodoroAppBot.{Bot, PomoManagement}

  @one_day_ago_in_seconds 24 * 60 * 60
  @commands [
    "!pomo - How much time is left.",
    "!pomo join - Join the pomo and begin tracking your stats.",
    "!pomo stats - See stats for all your previous pomos.",
    "!pomo today - See stats for all your pomos in the last 24 hours."
  ]

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
              "There is #{remaining_minutes} minutes remaining in the pomo. Use '!pomo join' to join the pomo or '!pomo help' for more info. "
            )
        end

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

      "pomo stats" ->
        case Pomos.get_member_by(sender) do
          %Pomos.Member{} = member ->
            Pomos.member_previous_channel_sessions(member.username, channel_user.id)
            |> calculate_stats()
            |> then(fn %{count: count, total_time: total_time} ->
              Bot.say(
                channel_user.username,
                "@#{sender} you have completed #{count} pomos, for a total of #{total_time} minutes."
              )
            end)

          nil ->
            Bot.say(channel_user.username, "@#{sender} you haven't completed any pomos yet.")
        end

      "pomo today" ->
        case Pomos.get_member_by(sender) do
          %Pomos.Member{} = member ->
            datetime = DateTime.add(DateTime.utc_now(), -@one_day_ago_in_seconds)

            Pomos.member_previous_channel_sessions_since(
              member.username,
              datetime,
              channel_user.id
            )
            |> calculate_stats()
            |> then(fn %{count: count, total_time: total_time} ->
              Bot.say(
                channel_user.username,
                "@#{sender} Today you have completed #{count} pomos, for a total of #{total_time} minutes."
              )
            end)

          nil ->
            Bot.say(channel_user.username, "@#{sender} you haven't completed any pomos yet.")
        end

      "pomo help" ->
        Bot.say(
          channel_user.username,
          "@#{sender} #{Enum.join(@commands, " ")}"
        )

      _ ->
        Logger.warn("Unknown command: #{command}")
    end
  rescue
    _ -> Logger.warn("Error occurred")
  end

  defp calculate_stats(list) do
    list
    |> Enum.reject(&is_nil(&1))
    |> Enum.reduce(%{count: 0, total_time: 0}, fn s, acc ->
      %{count: acc.count + 1, total_time: acc.total_time + s.pomo_time}
    end)
  end
end
