defmodule PomodoroAppBot.Bot do
  use TMI

  alias PomodoroApp.Accounts
  alias PomodoroApp.Pomos

  defguard is_broadcaster(channel, sender) when channel == sender

  @impl TMI.Handler
  def handle_message("!" <> command, sender, "#" <> sender) do
    user = Accounts.get_user_by_username(sender)

    case command do
      "pomostart" ->
        if Pomos.pomo_active_for?(user) do
          say(sender, "You already have a pomodoro running!")
        else
          case Pomos.create_pomo_session(%{
                 user_id: user.id,
                 pomo_time: user.pomo_time,
                 started_on: NaiveDateTime.utc_now()
               }) do
            {:ok, %Pomos.PomoSession{} = pomo_session} ->
              say(
                sender,
                "Pomodoro started, time to focus for the next #{pomo_session.pomo_time} minutes!"
              )

              seconds_delay = calculate_seconds_delay(pomo_session)
              enqueue_pomo_timer(user.id, sender, seconds_delay)

            {:error, _error} ->
              say(sender, "Something went wrong!")
          end
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
                say(sender, "Something went wrong!")
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

          _ ->
            case Accounts.update_user_pomo_time(user, pomotime) do
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

  defp calculate_seconds_delay(%Pomos.PomoSession{started_on: started_on, pomo_time: pomo_time}) do
    trigger_time = NaiveDateTime.add(started_on, pomo_time * 60, :second)

    NaiveDateTime.diff(trigger_time, NaiveDateTime.utc_now(), :second)
  end

  defp enqueue_pomo_timer(user_id, channel, seconds_delay) do
    %{user_id: user_id, channel: channel}
    |> PomodoroApp.Workers.EndPomo.new(schedule_in: seconds_delay)
    |> Oban.insert()
  end
end
