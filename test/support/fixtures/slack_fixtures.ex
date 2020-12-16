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

    %{
      "cache_ts" => 1_607_922_521,
      "members" => [
        %{
          "color" => "9f69e7",
          "deleted" => false,
          "id" => "XXXXXXXXXX",
          "is_admin" => true,
          "is_app_user" => false,
          "is_bot" => false,
          "is_owner" => true,
          "is_primary_owner" => true,
          "is_restricted" => false,
          "is_ultra_restricted" => false,
          "name" => "marc",
          "profile" => %{
            "avatar_hash" => "41b4d5781156",
            "display_name" => "marc",
            "display_name_normalized" => "marc",
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
end
