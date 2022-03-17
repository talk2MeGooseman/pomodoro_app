defmodule PomodoroAppBot.Bot do
  use TMI

  require Logger
  alias PomodoroAppWeb.Presence
  alias PomodoroApp.Accounts
  alias PomodoroApp.Pomos

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
            remaining_minutes = floor(calculate_seconds_remaining(pomo_session) / 60)

            say(
              sender,
              "There is #{remaining_minutes} minutes remaining in the pomo, you got this."
            )
        end

      "pomostart" ->
        if Pomos.pomo_active_for?(channel_user) do
          say(sender, "You already have a pomodoro running!")
        else
          start_pomo_session(channel_user, sender)
        end

      "pomoend" ->
        case Pomos.get_active_pomo_for(channel_user.id) do
          nil ->
            say(sender, "You have no active pomos.")

          pomo_session ->
            case Pomos.update_pomo_session(pomo_session, %{active: false}) do
              {:ok, _pomo_session} ->
                clean_up_presence(sender)

                say(sender, "Pomodoro ended!")

              {:error, _error} ->
                say(sender, "Uh oh, I had a problem ending current pomo.")
            end
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

          value ->
            case Accounts.update_user_pomo_time(channel_user, value) do
              {:error, _} ->
                say(sender, "Error updating pomo time.")

              {:ok, channel_user} ->
                say(sender, "Pomo time updated to #{channel_user.pomo_time} minutes.")
            end
        end

      _ ->
        global_commands(channel_user, command, sender)
    end
  end

  def handle_message("!" <> command, sender, "#" <> channel) do
    Accounts.get_user_by_username(channel)
    |> global_commands(command, sender)
  end

  def handle_message(_message, sender, "#" <> channel) do
    channel_user = Accounts.get_user_by_username(channel)

    if Pomos.pomo_active_for?(channel_user) do
      case Presence.get_by_key("channel:#{channel}", sender) do
        [] ->
          track_presence(channel, sender)
          say(channel, "Shhhh @#{sender}, it's time to focus!")

        %{
          metas: [
            %{
              reminded_at: reminded_at
            }
          ]
        } ->
          if NaiveDateTime.diff(NaiveDateTime.utc_now(), reminded_at) >
               @reminder_threshold_seconds do
            track_presence(channel, sender)
            say(channel, "Shhhh @#{sender}, it's time to focus!")
          else
            Logger.debug("Not reminding @#{sender} for channel #{channel}")
          end
      end
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

  defp global_commands(channel_user, command, sender) do
    case command do
      "pomotime" ->
        say(
          sender,
          "@#{sender} Pomo session time is currently set to #{channel_user.pomo_time} minutes."
        )

      "pomobreak" ->
        say(sender, "@#{sender} Pomo break time is #{channel_user.break_time} minutes.")
    end
  end

  defp pomo_session_attrs(user) do
    start_on = NaiveDateTime.utc_now()
    end_on = NaiveDateTime.add(start_on, user.pomo_time * 60)

    %{
      user_id: user.id,
      pomo_time: user.pomo_time,
      start: start_on,
      end: end_on
    }
  end

  defp calculate_seconds_remaining(%Pomos.PomoSession{end: end_on}) do
    NaiveDateTime.diff(end_on, NaiveDateTime.utc_now())
  end

  defp enqueue_pomo_timer(user_id, channel, seconds_delay) do
    %{user_id: user_id, channel: channel}
    |> PomodoroApp.Workers.EndPomo.new(schedule_in: seconds_delay)
    |> Oban.insert()
  end

  defp track_presence(channel, sender) do
    case Presence.get_by_key("channel:#{channel}", sender) do
      [] ->
        Presence.track(self(), "channel:#{channel}", sender, %{
          reminded_at: NaiveDateTime.utc_now()
        })

      presence when is_map(presence) ->
        Presence.update(self(), "channel:#{channel}", sender, %{
          reminded_at: NaiveDateTime.utc_now()
        })

      _ ->
        Logger.error("Could not track presence for #{sender} in #{channel}")
    end
  end

  defp clean_up_presence(channel) do
    Presence.list("channel:#{channel}")
    |> Map.keys()
    |> Enum.each(fn x -> Presence.untrack(self(), "channel:#{channel}", x) end)
  end
end
