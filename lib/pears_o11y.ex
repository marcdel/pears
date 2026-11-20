defmodule Pears.O11y do
  def set_masked_attribute(key, nil), do: O11y.set_attribute(key, nil)

  def set_masked_attribute(key, value) do
    masked_value = String.replace(value, ~r/./, "*")
    unmasked_value = String.slice(value, -8..-1)
    masked_value = masked_value <> unmasked_value

    O11y.set_attribute(key, masked_value)
  end

  def set_changeset_errors(%Ecto.Changeset{} = changeset) do
    error_string =
      changeset
      |> Ecto.Changeset.traverse_errors(fn {msg, _} -> msg end)
      |> Enum.map(fn {field, errors} -> "#{field}: #{Enum.join(errors, ", ")}" end)
      |> Enum.join(", ")

    O11y.set_error(error_string)
  end

  # Slack responses, interaction payloads and request params are nested maps
  # whose keys vary by endpoint, action and user input. o11y flattens maps into
  # one attribute per key, so setting them whole creates an open-ended set of
  # columns in Honeycomb. These helpers record a fixed set of scalar fields.

  @doc "Records ok/error/channel_id/ts from a Slack API response under `response.`"
  def set_slack_response(response) when is_map(response) do
    %{
      ok: response["ok"],
      error: response["error"],
      channel_id: slack_channel_id(response["channel"]),
      ts: response["ts"]
    }
    |> reject_nil_values()
    |> O11y.set_attributes(prefix: :response)
  end

  def set_slack_response(_response), do: :ok

  @doc "Records type, ids and action ids from a Slack interaction payload under `payload.`"
  def set_slack_interaction(payload) when is_map(payload) do
    action_ids =
      payload
      |> Map.get("actions")
      |> List.wrap()
      |> Enum.map(&nested(&1, "action_id"))
      |> Enum.reject(&is_nil/1)
      |> Enum.join(",")

    %{
      type: payload["type"],
      callback_id: payload["callback_id"],
      user_id: nested(payload["user"], "id"),
      team_id: nested(payload["team"], "id"),
      action_ids: action_ids
    }
    |> reject_nil_values()
    |> O11y.set_attributes(prefix: :payload)
  end

  def set_slack_interaction(_payload), do: :ok

  @doc "Records the sorted param names as one string, not one attribute per param"
  def set_param_keys(params) when is_map(params) do
    keys = params |> Map.keys() |> Enum.map(&to_string/1) |> Enum.sort() |> Enum.join(",")
    O11y.set_attribute(:param_keys, keys)
  end

  def set_param_keys(_params), do: :ok

  defp slack_channel_id(%{"id" => id}), do: id
  defp slack_channel_id(id) when is_binary(id), do: id
  defp slack_channel_id(_channel), do: nil

  defp nested(%{} = map, key), do: Map.get(map, key)
  defp nested(_value, _key), do: nil

  defp reject_nil_values(map), do: map |> Enum.reject(fn {_k, v} -> is_nil(v) end) |> Map.new()
end
