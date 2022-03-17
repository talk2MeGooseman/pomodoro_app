defmodule PomodoroApp.Repo.Migrations.CreateUsersAuthTables do
  use Ecto.Migration

  def change do
    execute "CREATE EXTENSION IF NOT EXISTS citext", ""

    create table(:users) do
      add :email, :citext, null: false
      add :hashed_password, :string, null: false
      add :confirmed_at, :naive_datetime
      add :pomo_time, :integer, null: true, default: 20
      add :provider, :string, null: false
      add :access_token, :string, null: true
      add :refresh_token, :string, null: true
      add :uid, :string
      add :username, :string
      add :break_time, :integer, null: true, default: 10

      timestamps()
    end

    create unique_index(:users, [:email])

    create table(:users_tokens) do
      add :user_id, references(:users, on_delete: :delete_all), null: false
      add :token, :binary, null: false
      add :context, :string, null: false
      add :sent_to, :string
      timestamps(updated_at: false)
    end

    create index(:users_tokens, [:user_id])
    create unique_index(:users_tokens, [:context, :token])

    create table(:pomo_sessions) do
      add :user_id, references(:users, on_delete: :delete_all), null: false
      add :start, :naive_datetime
      add :end, :naive_datetime
      add :pomo_time, :integer, null: false
      add :active, :boolean, null: false, default: true

      timestamps()
    end

    create index(:pomo_sessions, [:user_id])
  end
end
