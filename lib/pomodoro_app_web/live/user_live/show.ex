defmodule PomodoroAppWeb.UserLive.Show do
  use PomodoroAppWeb, :live_view
  on_mount PomodoroAppWeb.UserLiveAuth

  alias PomodoroApp.Accounts

  @impl true
  def mount(_params, session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(_params, session, socket) do
    IO.inspect(socket)
    {:noreply,
     socket
     |> assign(:page_title, page_title(socket.assigns.live_action))}
  end

  defp page_title(:show), do: "Show User"
  defp page_title(:edit), do: "Edit User"
end
