defmodule PomodoroAppWeb.OverlayLive.Show do
  use Surface.LiveView

  alias PomodoroApp.{Accounts, Pomos}
  alias PomodoroAppWeb.Components.Clock

  data user, :struct, default: nil
  data active_pomo, :struct, default: nil
  data past_pomo_sessions, :list, default: []

  @impl true
  def mount(%{"id" => user_id}, _session, socket) do
    if connected?(socket), do: Phoenix.PubSub.subscribe(PomodoroApp.PubSub, "overlay:#{user_id}")
    user = Accounts.get_user!(user_id)

    past_pomos = past_pomo_sessions(user_id)

    socket = assign(socket, :user, user)
    socket = assign(socket, :past_pomo_sessions, past_pomos)
    {:ok, assign(socket, :active_pomo, get_active_pomo(user_id))}
  end

  @impl true
  def handle_params(_params, _session, socket) do
    {:noreply,
     socket
     |> assign(:page_title, page_title(socket.assigns.live_action))}
  end

  @impl true
  def handle_info({:created_session, session}, socket) do
    {:noreply, assign(socket, :active_pomo, session)}
  end

  @impl true
  def handle_info({:updated_user, user}, socket) do
    {:noreply, assign(socket, :user, user)}
  end

  @impl true
  def handle_info({:updated_session, session}, socket) do
    socket =
      socket
      |> assign(:active_pomo, nil)
      |> update(:past_pomo_sessions, fn pomos -> [session | pomos] end)
      |> push_event("pomo_end", %{})

    {:noreply, socket}
  end

  defp page_title(_), do: ""

  def get_active_pomo(user_id) do
    Pomos.get_active_pomo_for(user_id)
  end

  def past_pomo_sessions(user_id) do
    DateTime.add(DateTime.utc_now(), -(18 * 60 * 60))
    |> PomodoroApp.Pomos.pomo_sessions_since(user_id)
  end
end
