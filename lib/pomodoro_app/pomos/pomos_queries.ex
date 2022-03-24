defmodule PomodoroApp.Pomos.PomosQueries do
  import Ecto.Query, warn: false

  alias PomodoroApp.Pomos.{PomoSession, Member, PomoSessionMember}
  alias PomodoroApp.Repo

  def sessions_with_id(query \\ session_base(), id) do
    query
    |> where([session], session.id == ^id)
  end

  def sessions_with_ids(query \\ session_base(), ids) do
    query
    |> where([session], session.id in ^ids)
  end

  def sessions_with_active(query \\ session_base(), active) when is_boolean(active) do
    query
    |> where([session], session.active == ^active)
  end

  def sessions_after(query \\ session_base(), %DateTime{} = datetime) do
    query
    |> where([session], session.start >= ^datetime)
  end

  def sessions_with_user_id(query \\ session_base(), user_id)
      when is_integer(user_id) or is_binary(user_id) do
    query
    |> where([session], session.user_id == ^user_id)
  end

  def sessions_joined_members(query \\ session_base()) do
    query
    |> join(:left, [session], member in assoc(session, :members))
  end

  def member_with_username(query \\ member_base(), username) when is_binary(username) do
    query
    |> where([member], member.username == ^username)
  end

  def members_joined_completed_channel_sessions(query \\ member_base(), user_id) do
    query
    |> join(:left, [member], session in assoc(member, :pomo_sessions),
      on: session.active == false and session.user_id == ^user_id
    )
  end

  def members_joined_completed_channel_sessions_since(
        query \\ member_base(),
        %DateTime{} = datetime,
        user_id
      )
      when is_binary(user_id) or is_integer(user_id) do
    query
    |> join(:left, [member], session in assoc(member, :pomo_sessions),
      on: session.active == false and session.start >= ^datetime and session.user_id == ^user_id
    )
  end

  defp session_base do
    from(_ in PomoSession, as: :session)
  end

  defp member_base do
    from(_ in Member, as: :member)
  end

  defp pomo_member_session_base do
    from(_ in PomoSessionMember, as: :session_member)
  end
end
