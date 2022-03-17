defmodule PomodoroAppBot.Bot do
  use TMI

  alias PomodoroApp.Accounts
  alias PomodoroApp.Pomos

  @impl TMI.Handler
  def handle_message("!" <> command, sender, "#" <> sender) do
    user = Accounts.get_user_by_username(sender)

    case command do
      "pomo" ->
        case Pomos.get_active_pomo_for(user.id) do
          nil ->
            say(sender, "There isnt a pomo currently active.")

          pomo_session ->
            remaining_minutes = floor(calculate_seconds_remaining(pomo_session) / 60)
            say(sender, "There is #{remaining_minutes} minutes remaining in the pomo, you got this.")
        end

      "pomostart" ->
        if Pomos.pomo_active_for?(user) do
          say(sender, "You already have a pomodoro running!")
        else
          start_pomo_session(user, sender)
        end

      "pomoend" ->
        case Pomos.get_active_pomo_for(user.id) do
          nil ->
            say(sender, "You have no active pomos.")

          pomo_session ->
            case Pomos.update_pomo_session(pomo_session, %{active: false}) do
              {:ok, _pomo_session} ->
                say(sender, "Pomodoro ended!")

              {:error, _error} ->
                say(sender, "Uh oh, I had a problem ending current pomo.")
            end
        end

      "pomotime" ->
        say(sender, "Your current pomo time is #{user.pomo_time} minutes.")

      "pomobreak" ->
        say(sender, "Your current break time is #{user.break_time} minutes.")

      "pomobreak " <> breaktime ->
        case Integer.parse(breaktime) do
          :error ->
            say(sender, "Invalid break time provided.")

          _ ->
            case Accounts.update_user_break_time(user, breaktime) do
              {:error, _} -> say(sender, "Error updating break time.")
              {:ok, user} -> say(sender, "Break time updated to #{user.break_time} minutes.")
            end
        end

      "pomotime " <> pomotime ->
        case Integer.parse(pomotime) do
          :error ->
            say(sender, "Invalid pomo time provided.")

          value ->
            case Accounts.update_user_pomo_time(user, value) do
              {:error, _} -> say(sender, "Error updating pomo time.")
              {:ok, user} -> say(sender, "Pomo time updated to #{user.pomo_time} minutes.")
            end
        end

      _ ->
        say(sender, "unrecognized command")
    end
  end

  def handle_message(_message, sender, "#" <> channel) do
    channel_user = Accounts.get_user_by_username(channel)

    if Pomos.pomo_active_for?(channel_user) do
      say(channel, "Shhhh @#{sender}, it's time to focus!")
    end
  end

  defp start_pomo_session(user, channel) do
    pomo_session_attrs(user)
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
        say(channel, "Something went wrong!")
    end
  end

  defp pomo_session_attrs(user) do
    start_on = NaiveDateTime.utc_now()
    end_on = NaiveDateTime.add(start_on, user.pomo_time * 60, :second)

    %{
      user_id: user.id,
      pomo_time: user.pomo_time,
      start: start_on,
      end: end_on
    }
  end

  defp calculate_seconds_remaining(%Pomos.PomoSession{end: end_on}) do
    NaiveDateTime.diff(end_on, NaiveDateTime.utc_now(), :second)
  end

  defp enqueue_pomo_timer(user_id, channel, seconds_delay) do
    %{user_id: user_id, channel: channel}
    |> PomodoroApp.Workers.EndPomo.new(schedule_in: seconds_delay)
    |> Oban.insert()
  end
end
