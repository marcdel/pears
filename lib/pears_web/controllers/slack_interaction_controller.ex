defmodule PearsWeb.SlackInteractionController do
  use OpenTelemetryDecorator
  use PearsWeb, :controller

  @decorate trace("slack_interaction_controller.create")
  def create(conn, %{"payload" => payload}) do
    case Jason.decode(payload) do
      {:ok, decoded_payload} ->
        O11y.set_attribute(:payload, decoded_payload)

        json(conn, %{})

      {:error, error} ->
        O11y.set_error(error)
        O11y.set_attribute(:payload, payload)

        conn
        |> put_status(400)
        |> json(%{})
    end
  end

  @decorate trace("slack_interaction_controller.create")
  def create(conn, params) do
    O11y.set_error("no payload in params")
    O11y.set_attribute(:params, params)

    conn
    |> put_status(400)
    |> json(%{})
  end
end
