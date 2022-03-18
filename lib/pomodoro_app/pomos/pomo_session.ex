defmodule PomodoroApp.Pomos.PomoSession do
  use Ecto.Schema
  import Ecto.Changeset

  schema "pomo_sessions" do
    field :start, :naive_datetime
    field :end, :naive_datetime
    field :pomo_time, :integer
    field :active, :boolean
    belongs_to :user, PomodoroApp.Accounts.User
    has_many :pomo_session_members, PomodoroApp.Pomos.PomoSessionMember
    has_many :members, through: [:pomo_session_members, :member]

    timestamps()
  end

  def create_changeset(pomo_session, attrs) do
    pomo_session
    |> cast(attrs, [:start, :end, :pomo_time, :active, :user_id])
    |> validate_required([:end, :pomo_time, :user_id])
  end

  def update_changeset(pomo_session, attrs) do
    pomo_session
    |> cast(attrs, [:active])
  end
end
