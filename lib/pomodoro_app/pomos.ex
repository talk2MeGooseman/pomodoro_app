defmodule PomodoroApp.Pomos do
  @moduledoc """
  The Pomos context.
  """

  import Ecto.Query, warn: false
  alias PomodoroApp.Repo
  alias PomodoroApp.Accounts.User
  alias PomodoroApp.Pomos.{PomoSession, Member, PomoSessionMember, PomosQueries}

  def build_pomo_session_attrs(%User{id: id, pomo_time: pomo_time}) do
    start_on = DateTime.utc_now()
    end_on = DateTime.add(start_on, pomo_time * 60)

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

  def pomo_sessions_since(%DateTime{} = time, user_id)
      when is_integer(user_id) or is_binary(user_id) do
    Repo.all(
      from p in PomoSession,
        where: p.start >= ^time,
        where: p.active == false,
        where: p.user_id == ^user_id,
        select: p
    )
  end

  def pomo_session_members(%PomoSession{id: id}) do
    PomosQueries.sessions_with_id(id)
    |> PomosQueries.sessions_joined_members()
    |> select([session, member], member)
    |> Repo.all()
  end

  def create_pomo_session(attrs) do
    %PomoSession{}
    |> PomoSession.create_changeset(attrs)
    |> Repo.insert()
    |> tap(fn {:ok, session} ->
      Phoenix.PubSub.broadcast(
        PomodoroApp.PubSub,
        "overlay:#{session.user_id}",
        {:created, session}
      )
    end)
  end

  def update_pomo_session(%PomoSession{} = pomo_session, attrs \\ %{}) do
    PomoSession.update_changeset(pomo_session, attrs)
    |> Repo.update()
    |> tap(fn {:ok, session} ->
      Phoenix.PubSub.broadcast(
        PomodoroApp.PubSub,
        "overlay:#{session.user_id}",
        {:updated, session}
      )
    end)
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

  def get_member_by(username) when is_binary(username) do
    Member
    |> where(username: ^username)
    |> Repo.one()
  end

  def member_previous_channel_sessions(username, user_id)
      when is_binary(username) and (is_integer(user_id) or is_binary(user_id)) do
    PomosQueries.member_with_username(username)
    |> PomosQueries.members_joined_completed_channel_sessions(user_id)
    |> select([member, session, session_member], session_member)
    |> Repo.all()
  end

  def member_previous_channel_sessions_since(username, %DateTime{} = datetime, user_id)
      when is_binary(username) and (is_integer(user_id) or is_binary(user_id)) do
    PomosQueries.member_with_username(username)
    |> PomosQueries.members_joined_completed_channel_sessions_since(datetime, user_id)
    |> select([member, session, session_member], session_member)
    |> Repo.all()
  end

  # Pomo Session Member

  def build_pomo_session_member_attrs(
        %Member{id: member_id},
        %PomoSession{id: id, end: end_on},
        goal \\ nil
      ) do

    time_remaining_in_minutes = DateTime.diff(end_on, DateTime.utc_now()) / 60
    %{
      pomo_time: floor(time_remaining_in_minutes),
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
