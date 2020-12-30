defmodule Pears.SlackFixtures do
  @moduledoc """
  This module defines test helpers for creating
  responses for the slack API endpoints.
  """

  def list_users_response(page \\ 1) do
    next_cursor =
      case page do
        1 -> "next_page"
        _ -> ""
      end

    id =
      case page do
        1 -> "XXXXXXXXXX"
        _ -> "YYYYYYYYYY"
      end

    name =
      case page do
        1 -> "marc"
        _ -> "milo"
      end

    %{
      "cache_ts" => 1_607_922_521,
      "members" => [
        %{
          "color" => "9f69e7",
          "deleted" => false,
          "id" => id,
          "is_admin" => true,
          "is_app_user" => false,
          "is_bot" => false,
          "is_owner" => true,
          "is_primary_owner" => true,
          "is_restricted" => false,
          "is_ultra_restricted" => false,
          "name" => name,
          "profile" => %{
            "avatar_hash" => "41b4d5781156",
            "display_name" => name,
            "display_name_normalized" => name,
            "fields" => nil,
            "first_name" => "Marc",
            "image_1024" =>
              "https://avatars.slack-edge.com/2018-02-07/987654321_abcdefg123456_1024.png",
            "image_192" =>
              "https://avatars.slack-edge.com/2018-02-07/987654321_abcdefg123456_192.png",
            "image_24" =>
              "https://avatars.slack-edge.com/2018-02-07/987654321_abcdefg123456_24.png",
            "image_32" =>
              "https://avatars.slack-edge.com/2018-02-07/987654321_abcdefg123456_32.png",
            "image_48" =>
              "https://avatars.slack-edge.com/2018-02-07/987654321_abcdefg123456_48.png",
            "image_512" =>
              "https://avatars.slack-edge.com/2018-02-07/987654321_abcdefg123456_512.png",
            "image_72" =>
              "https://avatars.slack-edge.com/2018-02-07/987654321_abcdefg123456_72.png",
            "image_original" =>
              "https://avatars.slack-edge.com/2018-02-07/987654321_abcdefg123456_original.png",
            "is_custom_image" => true,
            "last_name" => "Delagrammatikas",
            "phone" => "",
            "real_name" => "Marc Delagrammatikas",
            "real_name_normalized" => "Marc Delagrammatikas",
            "skype" => "",
            "status_emoji" => "",
            "status_expiration" => 0,
            "status_text" => "",
            "status_text_canonical" => "",
            "team" => "UTTTTTTTTTTL",
            "title" => ""
          },
          "real_name" => "Marc Delagrammatikas",
          "team_id" => "UTTTTTTTTTTL",
          "tz" => "America/Los_Angeles",
          "tz_label" => "Pacific Standard Time",
          "tz_offset" => -28_800,
          "updated" => 1_603_908_738
        }
      ],
      "ok" => true,
      "response_metadata" => %{
        "next_cursor" => "#{next_cursor}",
        "warnings" => ["superfluous_charset"]
      },
      "warning" => "superfluous_charset"
    }
  end

  def open_chat_response(params) do
    id = Keyword.get(params, :id, "D069C7QFK")

    %{
      "ok" => true,
      "no_op" => true,
      "already_open" => true,
      "channel" => %{
        "id" => id,
        "created" => 1_460_147_748,
        "is_im" => true,
        "is_org_shared" => false,
        "user" => "U069C7QF3",
        "last_read" => "0000000000.000000",
        "latest" => nil,
        "unread_count" => 0,
        "unread_count_display" => 0,
        "is_open" => true,
        "priority" => 0
      }
    }
  end
end
