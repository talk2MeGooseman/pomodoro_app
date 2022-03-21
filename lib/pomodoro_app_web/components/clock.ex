defmodule PomodoroAppWeb.Components.Clock do
  use Surface.Component

  @doc "Options to format the time in a different way"
  prop time_format, :string, default: nil

  def render(assigns) do
    ~F"""
    <section>
      <h1 id="clock" :hook="Clock" phx-update="ignore">00:00</h1>
    </section>
    """
  end
end
