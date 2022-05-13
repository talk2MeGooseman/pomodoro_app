defmodule PomodoroAppWeb.UserLive.Settings do
  use Surface.LiveView
  on_mount PomodoroAppWeb.UserLiveAuth

  alias PomodoroApp.Accounts
  alias PomodoroApp.Accounts.User
  alias PomodoroApp.Repo
  alias Surface.Components.Form
  alias Surface.Components.Form.{Label, Field, NumberInput, Checkbox, ErrorTag}

  @impl true
  def mount(_, _session, socket) do
    socket =
      if socket.assigns.current_user do
        user = Accounts.change_user_settings(socket.assigns.current_user)
        assign(socket, :user, user)
      else
        redirect(socket, to: "/auth/twitch")
      end

    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~F"""
    <Form for={@user} change="validate" submit="save" opts={autocomplete: "off"}>
      <Field name={:pomo_time}>
        <Label>Active work/study time</Label>
        <div class="control">
          <NumberInput />
          <ErrorTag />
        </div>
      </Field>
      <Field name={:break_time}>
        <Label>Break time</Label>
        <div class="control">
          <NumberInput />
          <ErrorTag field={:break_time} />
        </div>
      </Field>
      <Field name={:mute}>
        <Label>Mute the pomodoro bot</Label>
        <div class="control">
          <Checkbox />
          <ErrorTag />
        </div>
      </Field>
      <Field name={:disconnect}>
        <Label>Pomodoro bot will not join your channel</Label>
        <div class="control">
          <Checkbox />
          <ErrorTag />
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
      |> Map.merge(%{action: :insert})

    {:noreply, assign(socket, user: changeset)}
  end

  def handle_event("save", %{"user" => params}, socket) do
    user = socket.assigns.current_user
    changeset = User.user_settings_changeset(user, params)

    if changeset.valid? do
      Repo.update(changeset)
    end

    {:noreply, assign(socket, user: changeset)}
  end
end
