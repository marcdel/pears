defmodule Pears.O11yTest do
  # async: false — O11y.TestHelper stops/starts the :opentelemetry app per test
  use ExUnit.Case, async: false
  use O11y.TestHelper

  require OpenTelemetry.Tracer

  alias Pears.Slack
  alias Pears.Slack.Details

  # runtime.exs sets traces_exporter: :none in test, which overrides the pid
  # exporter otel_pid_reporter configures — point it at the test pid and restart.
  setup do
    Application.put_env(:opentelemetry, :traces_exporter, {:otel_exporter_pid, self()})
    Application.stop(:opentelemetry)
    {:ok, _} = Application.ensure_all_started(:opentelemetry)
    :ok
  end

  describe "set_slack_response/1" do
    test "keeps only fixed fields from a chat.postMessage response" do
      response = %{
        "ok" => true,
        "channel" => "C123",
        "ts" => "1700000000.000100",
        "message" => %{
          "text" => "hi",
          "blocks" => [%{"type" => "section", "block_id" => "abc"}],
          "bot_profile" => %{"id" => "B1", "name" => "pears"}
        }
      }

      OpenTelemetry.Tracer.with_span "test" do
        Pears.O11y.set_slack_response(response)
      end

      attributes = span_attributes("test")

      assert Map.keys(attributes) |> Enum.sort() ==
               ["response.channel_id", "response.ok", "response.ts"]

      assert attributes["response.channel_id"] == "C123"
    end

    test "reads the channel id from a conversations.open response" do
      response = %{"ok" => true, "channel" => %{"id" => "GROUPCHATID", "is_im" => false}}

      OpenTelemetry.Tracer.with_span "test" do
        Pears.O11y.set_slack_response(response)
      end

      attributes = span_attributes("test")

      assert Map.keys(attributes) |> Enum.sort() == ["response.channel_id", "response.ok"]
      assert attributes["response.channel_id"] == "GROUPCHATID"
    end
  end

  describe "set_slack_interaction/1" do
    test "keeps only fixed fields from an interaction payload" do
      payload = %{
        "type" => "block_actions",
        "user" => %{"id" => "U1", "username" => "marc"},
        "team" => %{"id" => "T1", "domain" => "pears"},
        "container" => %{"type" => "message", "message_ts" => "1"},
        "message" => %{"blocks" => [%{"type" => "section"}]},
        "actions" => [
          %{"action_id" => "yes", "value" => "1"},
          %{"action_id" => "no", "value" => "2"}
        ]
      }

      OpenTelemetry.Tracer.with_span "test" do
        Pears.O11y.set_slack_interaction(payload)
      end

      attributes = span_attributes("test")

      assert Map.keys(attributes) |> Enum.sort() ==
               ["payload.action_ids", "payload.team_id", "payload.type", "payload.user_id"]

      assert attributes["payload.action_ids"] == "yes,no"
    end
  end

  describe "set_param_keys/1" do
    test "records param names as one attribute" do
      OpenTelemetry.Tracer.with_span "test" do
        Pears.O11y.set_param_keys(%{"Pear Two" => "U2", "Pear One" => ""})
      end

      assert span_attributes("test") == %{"param_keys" => "Pear One,Pear Two"}
    end
  end

  describe "Slack.save_slack_names/3" do
    test "does not emit attributes keyed by pear names" do
      details = %Details{pears: [%{id: 1, name: "Pear One"}, %{id: 2, name: "Pear Two"}]}

      {:ok, _details} =
        Slack.save_slack_names(details, "Team One", %{"Pear One" => "", "Pear Two" => ""})

      keys = "slack.save_slack_names" |> span_attributes() |> Map.keys()

      for key <- keys, name <- ["Pear One", "Pear Two"] do
        refute String.contains?(key, name),
               "expected no span attribute keyed by #{inspect(name)}, found #{inspect(key)}"
      end
    end
  end

  # Returns the span's attributes with string keys and the "app." namespace removed.
  defp span_attributes(span_name) do
    assert_receive {:span, span(name: ^span_name, attributes: attributes)}

    attributes
    |> Tuple.to_list()
    |> List.last()
    |> Map.new(fn {key, value} -> {String.replace_prefix(to_string(key), "app.", ""), value} end)
  end
end
