defmodule PearsWeb.Notification do
  use PearsWeb, :live_component

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <!-- Global notification live region, render this permanently at the end of the document -->
      <div
        aria-live="assertive"
        class="pointer-events-none fixed bottom-0 right-0 flex items-end px-4 py-6 sm:items-start sm:p-6"
      >
        <div class="flex w-full flex-col items-center space-y-4 sm:items-end">
          <!--
        Notification panel, dynamically insert this into the live region when it needs to be displayed

        Entering: "transform ease-out duration-300 transition"
          From: "translate-y-2 opacity-0 sm:translate-y-0 sm:translate-x-2"
          To: "translate-y-0 opacity-100 sm:translate-x-0"
        Leaving: "transition ease-in duration-100"
          From: "opacity-100"
          To: "opacity-0"
      -->
          <div class={[
            "pointer-events-auto w-96 max-w-sm overflow-hidden",
            "rounded-lg bg-white shadow-lg ring-1 ring-black ring-opacity-5",
            @hide && "opacity-0"
          ]}>
            <div class="p-4">
              <div class="flex items-start">
                <div class="flex-shrink-0">
                  🎉
                </div>
                <div class="ml-3 w-0 flex-1 pt-0.5">
                  <p class="text-sm font-medium text-gray-900">Smash that Suggest button</p>
                  <p class="mt-1 text-sm text-gray-500">
                    That thing is actually useful now! It's been broken for a minute but is working again. Click
                    <a class="text-blue-500" href="https://streamable.com/ia9bat">here</a>
                    to see it in action.
                  </p>
                </div>
                <div class="ml-4 flex flex-shrink-0">
                  <button
                    phx-click="close"
                    phx-target={@myself}
                    type="button"
                    class="inline-flex rounded-md bg-white text-gray-400 hover:text-gray-500 focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:ring-offset-2"
                  >
                    <span class="sr-only">Close</span>
                    <svg class="h-5 w-5" viewBox="0 0 20 20" fill="currentColor" aria-hidden="true">
                      <path d="M6.28 5.22a.75.75 0 00-1.06 1.06L8.94 10l-3.72 3.72a.75.75 0 101.06 1.06L10 11.06l3.72 3.72a.75.75 0 101.06-1.06L11.06 10l3.72-3.72a.75.75 0 00-1.06-1.06L10 8.94 6.28 5.22z" />
                    </svg>
                  </button>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
    """
  end

  @impl true
  def mount(socket) do
    {:ok, assign(socket, hide: false)}
  end

  @impl true
  def handle_event("close", _params, socket) do
    {:noreply, assign(socket, hide: true)}
  end
end
