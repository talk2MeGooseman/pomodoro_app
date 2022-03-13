defmodule PomodoroApp.Pomos do
  @moduledoc """
  The Pomos context.
  """

  import Ecto.Query, warn: false
  alias PomodoroApp.Repo

  alias PomodoroApp.Pomos.{PomoSession}

  def get_pomo_session_by_user_id(id) do
    Repo.get_by(PomoSession, user_id: id)
  end

  def get_active_pomo_for(%PomodoroApp.Accounts.User{} = user) do
    PomoSession
    |> where(user_id: ^user.id)
    |> where(active: true)
    |> Repo.one()
  end

  def pomo_active_for?(%PomodoroApp.Accounts.User{} = user) do
    PomoSession
    |> where(user_id: ^user.id)
    |> where(active: true)
    |> Repo.exists?()
  end

  def create_pomo_session(attrs) do
    %PomoSession{}
    |> PomoSession.create_changeset(attrs)
    |> Repo.insert()
  end

  def update_pomo_session(%PomoSession{} = pomo_session, attrs \\ %{}) do
    PomoSession.update_changeset(pomo_session, attrs)
    |> Repo.update()
  end
end
