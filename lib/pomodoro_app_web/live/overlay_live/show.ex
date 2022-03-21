defmodule PomodoroAppWeb.OverlayLive.Show do
  use Surface.LiveView
  on_mount PomodoroAppWeb.UserLiveAuth

  alias PomodoroApp.{Accounts, Pomos}
  alias PomodoroAppWeb.Components.Clock

  data active_pomo, :struct, default: nil
  data past_pomo_sessions, :list, default: []

  @impl true
  def mount(_params, session, socket) do
    user_id = socket.assigns.current_user.id
    if connected?(socket), do: Phoenix.PubSub.subscribe(PomodoroApp.PubSub, "overlay:#{user_id}")

    sessions = past_pomo_sessions(user_id)

    socket = assign(socket, :past_pomo_sessions, sessions)
    {:ok, assign(socket, :active_pomo, get_active_pomo(user_id))}
  end

  @impl true
  def handle_params(_params, session, socket) do
    {:noreply,
     socket
     |> assign(:page_title, page_title(socket.assigns.live_action))}
  end

  @impl true
  def handle_info({:created, session}, socket) do
    socket = assign(socket, :active_pomo, session)
    {:noreply, socket}
  end

  @impl true
  def handle_info({:updated, session}, socket) do
    socket =
      socket
      |> assign(:active_pomo, nil)
      |> update(:past_pomo_sessions, fn pomos -> [session | pomos] end)

    {:noreply, socket}
  end

  defp page_title(:show), do: "Show User"
  defp page_title(:edit), do: "Edit User"

  def get_active_pomo(user_id) do
    Pomos.get_active_pomo_for(user_id)
  end

  def past_pomo_sessions(user_id) do
    DateTime.add(DateTime.utc_now(), -86400)
    |> PomodoroApp.Pomos.pomo_sessions_since(user_id)
  end
end
