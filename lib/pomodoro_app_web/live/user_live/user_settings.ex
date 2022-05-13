defmodule PomodoroAppWeb.UserLive.Settings do
  use Surface.LiveView

  alias PomodoroApp.Accounts
  alias PomodoroApp.Accounts.User
  alias PomodoroApp.Repo
  alias Surface.Components.Form
  alias Surface.Components.Form.{Label, Field, NumberInput, Checkbox, ErrorTag}

  @impl true
  def mount(_, _session, socket) do
    data = Accounts.get_user!(1)
    user = Accounts.change_user_settings(data)
    socket = assign(socket, :user, user)
    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~F"""
    <Form for={@user} change="validate" submit="save" opts={autocomplete: "off"}>
      <Field name={:pomo_time}>
        <ErrorTag />
        <Label>Active work/study time</Label>
        <div class="control">
          <NumberInput />
        </div>
      </Field>
      <Field name={:break_time}>
        <ErrorTag field={:break_time} />
        <Label>Break time</Label>
        <div class="control">
          <NumberInput />
        </div>
      </Field>
      <Field name={:mute}>
        <ErrorTag />
        <Label>Mute the pomodoro bot</Label>
        <div class="control">
          <Checkbox />
        </div>
      </Field>
      <Field name={:disconnect}>
        <ErrorTag />
        <Label>Pomodoro bot will not join your channel</Label>
        <div class="control">
          <Checkbox />
        </div>
      </Field>
      <button disabled={!@user.valid?} type="submit">Save</button>
    </Form>
    """
  end

  @impl true
  def handle_event("validate", %{"user" => params}, socket) do
    changeset =
      %Accounts.User{}
      |> Accounts.change_user_settings(params)

    {:noreply, assign(socket, user: changeset)}
  end

  def handle_event("save", %{"user" => params}, socket) do
    user = Accounts.get_user!(1)

    changeset = User.user_settings_changeset(user, params)

    if changeset.valid? do
      Repo.update(changeset)
    end

    {:noreply, assign(socket, user: changeset)}
  end
end
