defmodule PomodoroAppWeb.Components.Clock do
  use Surface.Component

  @doc "Options to format the time in a different way"
  prop time_format, :string, default: nil

  @doc "The color"
  prop color, :string, values!: ["danger", "info", "warning"], default: "info"

  def render(assigns) do
    ~F"""
    <section class={"phx-hero", "alert-#{@color}": @color}>
      <h1 id="clock" :hook="Clock">Clock</h1>
    </section>
    """
  end
end
