defmodule PomodoroAppWeb.Presence do
  @moduledoc """
  Provides presence tracking to channels and processes.

  See the [`Phoenix.Presence`](https://hexdocs.pm/phoenix/Phoenix.Presence.html)
  docs for more details.
  """
  use Phoenix.Presence,
    otp_app: :pomodoro_app,
    pubsub_server: PomodoroApp.PubSub

  require Logger

  def track_pomo_presence(channel, sender) do
    case get_by_key("channel:#{channel}", sender) do
      [] ->
        track(self(), "channel:#{channel}", sender, %{
          reminded_at: DateTime.utc_now()
        })

      presence when is_map(presence) ->
        update(self(), "channel:#{channel}", sender, %{
          reminded_at: DateTime.utc_now()
        })

      _ ->
        Logger.error("Could not track presence for #{sender} in #{channel}")
    end
  end

  def clean_up_pomo_presence(channel, pid \\ self()) do
    list("channel:#{channel}")
    |> Map.keys()
    |> Enum.each(fn member ->
      update(pid, "channel:#{channel}", member, %{
        reminded_at: nil
      })
    end)
  end
end
