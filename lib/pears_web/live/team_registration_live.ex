defmodule PearsWeb.TeamRegistrationLive do
  use PearsWeb, :live_view

  alias Pears.Accounts
  alias Pears.Accounts.Team

  def render(assigns) do
    ~H"""
    <.error :if={@check_errors}>
      Oops, something went wrong! Please check the errors below.
    </.error>
    <main class="min-h-screen bg-white flex">
      <div class="flex-1 flex flex-col justify-center py-12 px-4 sm:px-6 lg:flex-none lg:px-20 xl:px-32">
        <div class="mx-auto w-full max-w-sm lg:w-96">
          <div>
            <div
              class="flex text-sm border-2 border-transparent rounded-full focus:outline-none focus:border-green-300 transition duration-150 ease-in-out"
              id="user-menu"
              aria-label="User menu"
              aria-haspopup="true"
            >
              <span class="inline-flex items-center justify-center h-12 w-12 rounded-full bg-green-500">
                <span class="text-lg font-medium leading-none text-white">🍐</span>
              </span>
            </div>
            <h2 class="mt-6 text-3xl leading-9 font-extrabold text-gray-900 xl:w-64">
              Create your team
            </h2>
            <p class="mt-2 text-sm leading-5 text-gray-600 max-w">
              Or
              <.link
                navigate={~p"/teams/log_in"}
                class="font-medium text-green-600 hover:text-green-500 focus:outline-none focus:underline transition ease-in-out duration-150"
              >
                log in
              </.link>
            </p>
          </div>

          <div class="mt-8">
            <div class="mt-6">
              <.simple_form
                for={@form}
                id="registration_form"
                phx-submit="save"
                phx-change="validate"
                phx-trigger-action={@trigger_submit}
                action={~p"/teams/log_in?_action=registered"}
                method="post"
              >
                <.input field={@form[:name]} type="text" label="Name" required />
                <.input field={@form[:password]} type="password" label="Password" required />

                <:actions>
                  <.button phx-disable-with="Registering account...">Register</.button>
                </:actions>
              </.simple_form>
            </div>
          </div>
        </div>
      </div>
      <div class="hidden lg:flex flex-col items-center justify-center w-0 flex-1">
        <img class="inset-0 object-cover" src={~p"/images/login.svg"} alt="" />
      </div>
    </main>
    """
  end

  def mount(_params, _session, socket) do
    changeset = Accounts.change_team_registration(%Team{})

    socket =
      socket
      |> assign(trigger_submit: false, check_errors: false)
      |> assign_form(changeset)

    {:ok, socket, temporary_assigns: [form: nil]}
  end

  def handle_event("save", %{"team" => team_params}, socket) do
    case Accounts.register_team(team_params) do
      {:ok, team} ->
        {:ok, _} =
          Accounts.deliver_team_confirmation_instructions(
            team,
            &url(~p"/teams/confirm/#{&1}")
          )

        changeset = Accounts.change_team_registration(team)
        {:noreply, socket |> assign(trigger_submit: true) |> assign_form(changeset)}

      {:error, %Ecto.Changeset{} = changeset} ->
        socket =
          socket
          # |> assign(check_errors: true) # Show the <.error> component
          |> put_flash(:error, "Oops, something went wrong! Please check the errors below.")
          |> assign_form(changeset)

        {:noreply, socket}
    end
  end

  def handle_event("validate", %{"team" => team_params}, socket) do
    changeset = Accounts.change_team_registration(%Team{}, team_params)
    {:noreply, assign_form(socket, Map.put(changeset, :action, :validate))}
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    form = to_form(changeset, as: "team")

    if changeset.valid? do
      assign(socket, form: form, check_errors: false)
    else
      assign(socket, form: form)
    end
  end
end
