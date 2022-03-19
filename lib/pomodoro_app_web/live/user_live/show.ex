defmodule PomodoroAppWeb.UserLive.Show do
  use PomodoroAppWeb, :live_view
  on_mount PomodoroAppWeb.UserLiveAuth

  alias PomodoroApp.{Accounts, Pomos}

  @impl true
  def mount(_params, session, socket) do
    user_id = socket.assigns.current_user.id
    if connected?(socket), do: Phoenix.PubSub.subscribe(PomodoroApp.PubSub, "overlay:#{user_id}")

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
    socket
    |> assign(:active_pomo, nil)
    |> update(:session, fn pomos -> [session | pomos] end)
    {:noreply, socket}
  end

  defp page_title(:show), do: "Show User"
  defp page_title(:edit), do: "Edit User"

  def get_active_pomo(user_id) do
    Pomos.get_active_pomo_for(user_id)
  end
end
