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
                 stated_on: NaiveDateTime.utc_now()
               }) do
            {:ok, pomo_session} ->
              say(
                sender,
                "Pomodoro started, time to focus for the next #{pomo_session.pomo_time} minutes!"
              )

            {:error, _error} ->
              say(sender, "Something went wrong!")
          end
        end

      "pomoend" ->
        case Pomos.get_active_pomo_for(user) do
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

      "breaktime" ->
        say(sender, "Your current break time is #{user.break_time} minutes.")

      "breaktime " <> breaktime ->
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

  def handle_message("!" <> command, sender, "#" <> channel) do
    case command do
      "echo " <> rest ->
        say(channel, rest)

      _ ->
        say(channel, "unrecognized command")
    end
  end

  def handle_message(message, sender, "#" <> channel) do
    channel_user = Accounts.get_user_by_username(channel)

    if Pomos.pomo_active_for?(channel_user) do
      say(channel, "Shhhh @#{sender}, it's time to focus!")
    end
  end
end
