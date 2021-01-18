defmodule Pears.SlackFixtures do
  @moduledoc """
  This module defines test helpers for creating
  responses for the slack API endpoints.
  """

  @valid_code "169403114024.1535385215366.e6118897ed25c4e0d78803d3217ac7a98edabf0cf97010a115ef264771a1f98c"
  @valid_token "xoxb-XXXXXXXX-XXXXXXXX-XXXXX"
  @valid_user_token "xoxp-XXXXXXXX-XXXXXXXX-XXXXX"

  def valid_code, do: @valid_code
  def valid_token, do: @valid_token
  def valid_user_token, do: @valid_user_token

  def valid_token_response(attrs \\ %{}) do
    Map.merge(
      %{
        "access_token" => @valid_token,
        "app_id" => "XXXXXXXXXX",
        "authed_user" => %{
          "access_token" => @valid_user_token,
          "id" => "UTTTTTTTTTTL",
          "scope" => "search:read",
          "token_type" => "user"
        },
        "bot_user_id" => "UTTTTTTTTTTR",
        "enterprise" => nil,
        "ok" => true,
        "response_metadata" => %{"warnings" => ["superfluous_charset"]},
        "scope" =>
          "commands,chat:write,app_mentions:read,channels:read,im:read,im:write,im:history,users:read,chat:write.public",
        "team" => %{"id" => "XXXXXXXXXX", "name" => "Team Installing Your Hook"},
        "token_type" => "bot",
        "warning" => "superfluous_charset"
      },
      attrs
    )
  end

  def invalid_token_response do
    %{
      "error" => "invalid_code",
      "ok" => false,
      "response_metadata" => %{"warnings" => ["superfluous_charset"]},
      "warning" => "superfluous_charset"
    }
  end

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

  def conversations_response(page: 1) do
    %{
      "channels" => [
        %{
          "created" => 123_456_789,
          "creator" => "UTTTTTTTTTTL",
          "id" => "XXXXXXXXXX",
          "is_archived" => false,
          "is_channel" => true,
          "is_ext_shared" => false,
          "is_general" => true,
          "is_group" => false,
          "is_im" => false,
          "is_member" => false,
          "is_mpim" => false,
          "is_org_shared" => false,
          "is_pending_ext_shared" => false,
          "is_private" => false,
          "is_shared" => false,
          "name" => "random",
          "name_normalized" => "random",
          "num_members" => 1,
          "parent_conversation" => nil,
          "pending_connected_team_ids" => [],
          "pending_shared" => [],
          "previous_names" => [],
          "purpose" => %{
            "creator" => "",
            "last_set" => 0,
            "value" =>
              "A place for non-work-related flimflam, faffing, hodge-podge or jibber-jabber you'd prefer to keep out of more focused work-related channels."
          },
          "shared_team_ids" => ["XXXXXXXXXX"],
          "topic" => %{
            "creator" => "",
            "last_set" => 0,
            "value" => "Company-wide announcements and work-based matters"
          },
          "unlinked" => 0
        }
      ],
      "ok" => true,
      "response_metadata" => %{
        "next_cursor" => "page_two",
        "warnings" => ["superfluous_charset"]
      },
      "warning" => "superfluous_charset"
    }
  end

  def conversations_response(page: 2) do
    %{
      "channels" => [
        %{
          "created" => 123_456_789,
          "creator" => "UTTTTTTTTTTL",
          "id" => "XXXXXXXXXX",
          "is_archived" => false,
          "is_channel" => true,
          "is_ext_shared" => false,
          "is_general" => true,
          "is_group" => false,
          "is_im" => false,
          "is_member" => false,
          "is_mpim" => false,
          "is_org_shared" => false,
          "is_pending_ext_shared" => false,
          "is_private" => false,
          "is_shared" => false,
          "name" => "general",
          "name_normalized" => "general",
          "num_members" => 1,
          "parent_conversation" => nil,
          "pending_connected_team_ids" => [],
          "pending_shared" => [],
          "previous_names" => [],
          "purpose" => %{
            "creator" => "",
            "last_set" => 0,
            "value" =>
              "This channel is for team-wide communication and announcements. All team members are in this channel."
          },
          "shared_team_ids" => ["XXXXXXXXXX"],
          "topic" => %{
            "creator" => "",
            "last_set" => 0,
            "value" => "Company-wide announcements and work-based matters"
          },
          "unlinked" => 0
        }
      ],
      "ok" => true,
      "response_metadata" => %{
        "next_cursor" => "",
        "warnings" => ["superfluous_charset"]
      },
      "warning" => "superfluous_charset"
    }
  end
end
