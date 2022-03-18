defmodule PomodoroApp.Pomos.Member do
  use Ecto.Schema
  import Ecto.Changeset

  schema "members" do
    field :username, :string
    has_many :pomo_session_members, PomodoroApp.Pomos.PomoSessionMember
    has_many :pomo_sessions, through: [:pomo_session_members, :pomo_session]

    timestamps()
  end

  def create_changeset(member, attrs) do
    member
    |> cast(attrs, [:username])
    |> validate_required([:username])
    |> unique_constraint([:username])
  end
end
