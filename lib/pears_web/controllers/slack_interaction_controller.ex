defmodule PearsWeb.SlackInteractionController do
  use OpenTelemetryDecorator
  use PearsWeb, :controller
  alias Pears.O11y

  @decorate trace("slack_interaction.create")
  def create(conn, %{"payload" => payload}) do
    case Jason.decode(payload) do
      {:ok, decoded_payload} ->
        O11y.set_attribute(:payload, decoded_payload)

        json(conn, %{})

      {:error, error} ->
        O11y.set_attribute(:error, error)

        conn
        |> put_status(400)
        |> json(%{})
    end
  end
end
