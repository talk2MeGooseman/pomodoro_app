defmodule PomodoroApp.Pomos.PomoSessionMember do
  use Ecto.Schema
  import Ecto.Changeset

  schema "pomo_session_members" do
    field :pomo_time, :integer
    field :goal, :string
    belongs_to :member, PomodoroApp.Pomos.Member
    belongs_to :pomo_session, PomodoroApp.Pomos.PomoSession

    timestamps()
  end

  def create_changeset(pomo_session_members, attrs) do
    pomo_session_members
    |> cast(attrs, [:pomo_time, :goal, :member_id, :pomo_session_id])
    |> validate_required([:member_id, :pomo_time, :pomo_session_id])
    |> unique_constraint([:pomo_session_id, :member_id])
  end
end
