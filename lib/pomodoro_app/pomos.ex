defmodule PomodoroApp.Pomos do
  @moduledoc """
  The Pomos context.
  """

  import Ecto.Query, warn: false
  alias PomodoroApp.Repo
  alias PomodoroApp.Accounts.User
  alias PomodoroApp.Pomos.{PomoSession, Member, PomoSessionMember}

  def build_pomo_session_attrs(%User{id: id, pomo_time: pomo_time}) do
    start_on = NaiveDateTime.utc_now()
    end_on = NaiveDateTime.add(start_on, pomo_time * 60)

    %{
      user_id: id,
      pomo_time: pomo_time,
      start: start_on,
      end: end_on
    }
  end

  def get_pomo_session_by_user_id(id) do
    Repo.get_by(PomoSession, user_id: id)
  end

  def get_pomo_session_by_id(id) do
    Repo.get(PomoSession, id)
  end

  def get_active_pomo_for(user_id) do
    PomoSession
    |> where(user_id: ^user_id)
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

  # Member

  def find_or_create_member(username) do
    case get_member_by(username) do
      nil -> create_member(%{username: username})
      member -> {:ok, member}
    end
  end

  def create_member(attrs) do
    %Member{}
    |> Member.create_changeset(attrs)
    |> Repo.insert()
  end

  def get_member_by(username) do
    Member
    |> where(username: ^username)
    |> Repo.one()
  end

  # Pomo Session Member

  def build_pomo_session_member_attrs(
        %Member{id: member_id},
        %PomoSession{id: id, pomo_time: pomo_time},
        goal \\ nil
      ) do
    %{
      pomo_time: pomo_time,
      goal: goal,
      member_id: member_id,
      pomo_session_id: id
    }
  end

  def create_pomo_session_member(attrs) do
    %PomoSessionMember{}
    |> PomoSessionMember.create_changeset(attrs)
    |> Repo.insert()
  end
end
