defmodule PomodoroApp.Accounts.AccountQueries do
  import Ecto.Query, warn: false

  alias PomodoroApp.Accounts.{User}

  def with_id(query \\ user_base(), id) do
    query
    |> where([user], user.id == ^id)
  end

  def with_disconnect(query \\ user_base(), value) do
    query
    |> where([user], user.disconnect == ^value)
  end

  def usernames_not_in(query \\ user_base(), usernames) do
    query
    |> where([user], user.username not in ^usernames)
  end

  def sessions_with_ids(query \\ user_base(), ids) do
    query
    |> where([user], user.id in ^ids)
  end

  def with_username(query \\ user_base(), username) when is_binary(username) do
    query
    |> where([user], user.username == ^username)
  end

  defp user_base do
    from(_ in User, as: :user)
  end
end
