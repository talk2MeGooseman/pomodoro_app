defmodule PomodoroAppBot.Bot do
  use TMI


  defguard is_broadcaster(channel, sender) when channel == sender

  @impl TMI.Handler
  def handle_message("!" <> command, sender, "#" <> sender) do
    case command do
      "pomotime " <> pomotime ->
        case Integer.parse(pomotime) do
          :error -> say(sender, "Invalid pomo time provided.")
          _ -> say(sender, "Set pomo time to #{pomotime} minutes")
        end

      _ ->
        say(sender, "unrecognized command")
    end
  end

  def handle_message("!" <> command, sender, "#" <> chat) do
    case command do
      "echo " <> rest ->
        say(chat, rest)

      _ ->
        say(chat, "unrecognized command")
    end
  end

  def handle_message(message, sender, chat) do
    Logger.debug("Message in #{chat} from #{sender}: #{message}")
  end
end
