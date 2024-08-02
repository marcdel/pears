defmodule PearsWeb.TeamLoginLive do
  use PearsWeb, :live_view
  use OpenTelemetryDecorator

  def render(assigns) do
    ~H"""
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
              Log in
            </h2>
            <p class="mt-2 text-sm leading-5 text-gray-600 max-w">
              Or
              <.link
                navigate={~p"/teams/register"}
                class="font-medium text-green-600 hover:text-green-500 focus:outline-none focus:underline transition ease-in-out duration-150"
              >
                create your team
              </.link>
            </p>
          </div>

          <div class="mt-8">
            <div class="mt-6">
              <.simple_form for={@form} id="login_form" action={~p"/teams/log_in"} phx-update="ignore">
                <.input field={@form[:name]} type="text" label="Name" required />
                <.input field={@form[:password]} type="password" label="Password" required />

                <:actions>
                  <.input field={@form[:remember_me]} type="checkbox" label="Remember me" />
                  <%!-- <.link href={~p"/teams/reset_password"} class="text-sm font-semibold">
                  Forgot your password?
                </.link> --%>
                </:actions>
                <:actions>
                  <.button phx-disable-with="Logging in...">
                    Log in
                  </.button>
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

  @decorate trace("PearsWeb.TeamLoginLive.mount", include: [:name, :socket])
  def mount(_params, _session, socket) do
    name = Phoenix.Flash.get(socket.assigns.flash, :name)
    form = to_form(%{"name" => name}, as: "team")
    {:ok, assign(socket, form: form), temporary_assigns: [form: form]}
  end
end
