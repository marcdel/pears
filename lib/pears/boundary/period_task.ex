defmodule PeriodicTask do
  @moduledoc """
    Can be used the way a `GenServer` normally would

    defmodule Counter do
      use PeriodicTask,
        interval: :timer.seconds(1)

      require Logger

      def handle_tick(count) do
        new_count = count + 1
        Logger.info("Count: #\{new_count\}")

        {:noreply, new_count}
      end
    end
  """

  defmacro __using__(opts) do
    interval = Keyword.fetch!(opts, :interval)

    quote do
      use GenServer

      def start_link(opts \\ []) do
        GenServer.start_link(__MODULE__, opts, name: __MODULE__)
      end

      @impl GenServer
      def init(state) do
        send(self(), :tick)
        {:ok, state}
      end

      @impl GenServer
      def handle_info(:tick, state) do
        schedule_next()
        handle_tick(state)
      end

      def schedule_next do
        Process.send_after(self(), :tick, unquote(interval))
      end

      def handle_tick(state) do
        raise """
          Please override me! The overridden handle_tick method must take
          the current state as an argument and return one of:

          {:noreply, new_state}
          | {:noreply, new_state, timeout() | :hibernate | {:continue, term()}}
          | {:stop, reason :: term(), new_state}
        """

        {:noreply, state}
      end

      defoverridable start_link: 0, handle_tick: 1
    end
  end
end
