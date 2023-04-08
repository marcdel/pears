defmodule Pears.AccountsTest do
  use Pears.DataCase
  import Pears.AccountsFixtures

  alias Pears.Accounts
  alias Pears.Accounts.{Team, TeamToken}

  describe "get_team_by_name/1" do
    test "does not return the team if the name does not exist" do
      refute Accounts.get_team_by_name("unknown team")
    end

    test "returns the team if the name exists" do
      %{id: id} = team = team_fixture()
      assert %Team{id: ^id} = Accounts.get_team_by_name(team.name)
    end
  end

  describe "get_team_by_name_and_password/2" do
    test "does not return the team if the name does not exist" do
      refute Accounts.get_team_by_name_and_password("unknown team", "hello world!")
    end

    test "does not return the team if the password is not valid" do
      team = team_fixture()
      refute Accounts.get_team_by_name_and_password(team.name, "invalid")
    end

    test "returns the team if the name and password are valid" do
      %{id: id} = team = team_fixture()

      assert %Team{id: ^id} =
               Accounts.get_team_by_name_and_password(team.name, valid_team_password())
    end
  end

  describe "get_team_by_email/1" do
    test "does not return the team if the email does not exist" do
      refute Accounts.get_team_by_email("unknown@example.com")
    end

    test "returns the team if the email exists" do
      %{id: id} = team = team_fixture()
      assert %Team{id: ^id} = Accounts.get_team_by_email(team.email)
    end
  end

  describe "get_team_by_email_and_password/2" do
    test "does not return the team if the email does not exist" do
      refute Accounts.get_team_by_email_and_password("unknown@example.com", "hello world!")
    end

    test "does not return the team if the password is not valid" do
      team = team_fixture()
      refute Accounts.get_team_by_email_and_password(team.email, "invalid")
    end

    test "returns the team if the email and password are valid" do
      %{id: id} = team = team_fixture()

      assert %Team{id: ^id} =
               Accounts.get_team_by_email_and_password(team.email, valid_team_password())
    end
  end

  describe "get_team!/1" do
    test "raises if id is invalid" do
      assert_raise Ecto.NoResultsError, fn ->
        Accounts.get_team!(-1)
      end
    end

    test "returns the team with the given id" do
      %{id: id} = team = team_fixture()
      assert %Team{id: ^id} = Accounts.get_team!(team.id)
    end
  end

  describe "register_team/1" do
    test "requires name and password to be set" do
      {:error, changeset} = Accounts.register_team(%{})

      assert %{
               password: ["can't be blank"],
               name: ["can't be blank"]
             } = errors_on(changeset)
    end

    test "validates name, email, and password when given" do
      {:error, changeset} =
        Accounts.register_team(%{
          name: " ",
          email: "not valid",
          password: "short"
        })

      assert %{
               name: ["can't be blank"],
               email: ["must have the @ sign and no spaces"],
               password: ["should be at least 6 character(s)"]
             } = errors_on(changeset)
    end

    test "validates maximum values for name, email, and password for security" do
      too_long = String.duplicate("db", 100)

      {:error, changeset} =
        Accounts.register_team(%{
          name: too_long,
          email: too_long,
          password: too_long
        })

      assert "should be at most 160 character(s)" in errors_on(changeset).name
      assert "should be at most 160 character(s)" in errors_on(changeset).email
      assert "should be at most 72 character(s)" in errors_on(changeset).password
    end

    test "validates name uniqueness" do
      %{name: name} = team_fixture()
      {:error, changeset} = Accounts.register_team(%{name: name})
      assert "has already been taken" in errors_on(changeset).name

      # Now try with the upper cased name too, to check that name case is ignored.
      {:error, changeset} = Accounts.register_team(%{name: String.upcase(name)})
      assert "has already been taken" in errors_on(changeset).name
    end

    test "validates email uniqueness" do
      %{email: email} = team_fixture()
      {:error, changeset} = Accounts.register_team(%{email: email})
      assert "has already been taken" in errors_on(changeset).email

      # Now try with the upper cased email too, to check that email case is ignored.
      {:error, changeset} = Accounts.register_team(%{email: String.upcase(email)})
      assert "has already been taken" in errors_on(changeset).email
    end

    test "registers teams with a hashed password" do
      name = unique_team_name()
      email = unique_team_email()
      {:ok, team} = Accounts.register_team(valid_team_attributes(name: name, email: email))
      assert team.email == email
      assert is_binary(team.hashed_password)
      assert is_nil(team.confirmed_at)
      assert is_nil(team.password)
      refute team.enabled
    end
  end

  describe "change_team_registration/2" do
    test "returns a changeset" do
      assert %Ecto.Changeset{} = changeset = Accounts.change_team_registration(%Team{})
      assert changeset.required == [:password, :name]
    end

    test "allows fields to be set" do
      name = unique_team_name()
      email = unique_team_email()
      password = valid_team_password()

      changeset =
        Accounts.change_team_registration(
          %Team{},
          valid_team_attributes(name: name, email: email, password: password)
        )

      assert changeset.valid?
      assert get_change(changeset, :name) == name
      assert get_change(changeset, :email) == email
      assert get_change(changeset, :password) == password
      assert is_nil(get_change(changeset, :hashed_password))
    end
  end

  describe "change_team_name/2" do
    test "returns a team changeset" do
      assert %Ecto.Changeset{} = changeset = Accounts.change_team_name(%Team{})
      assert changeset.required == [:name]
    end
  end

  describe "update_team_name/3" do
    setup do
      %{team: team_fixture()}
    end

    test "requires name to change", %{team: team} do
      {:error, changeset} = Accounts.update_team_name(team, valid_team_password(), %{})
      assert %{name: ["did not change"]} = errors_on(changeset)
    end

    test "validates name", %{team: team} do
      {:error, changeset} = Accounts.update_team_name(team, valid_team_password(), %{name: " "})

      assert %{name: ["did not change", "can't be blank"]} = errors_on(changeset)
    end

    test "validates maximum value for name for security", %{team: team} do
      too_long = String.duplicate("db", 100)

      {:error, changeset} =
        Accounts.update_team_name(team, valid_team_password(), %{name: too_long})

      assert "should be at most 160 character(s)" in errors_on(changeset).name
    end

    test "validates name uniqueness", %{team: team} do
      %{name: name} = team_fixture()

      {:error, changeset} = Accounts.update_team_name(team, valid_team_password(), %{name: name})

      assert "has already been taken" in errors_on(changeset).name
    end

    test "validates current password", %{team: team} do
      {:error, changeset} =
        Accounts.update_team_name(team, "invalid", %{name: unique_team_name()})

      assert %{current_password: ["is not valid"]} = errors_on(changeset)
    end

    test "applies the name and persists it", %{team: team} do
      name = unique_team_name()
      {:ok, team} = Accounts.update_team_name(team, valid_team_password(), %{name: name})
      assert team.name == name
      assert Accounts.get_team!(team.id).name == name
    end

    test "does not update name if team name changed", %{team: team} do
      {:error, changeset} =
        Accounts.update_team_name(team, valid_team_password(), %{name: team.name})

      assert %{name: ["did not change"]} = errors_on(changeset)
      assert Repo.get!(Team, team.id).name == team.name
    end
  end

  describe "change_team_email/2" do
    test "returns a team changeset" do
      assert %Ecto.Changeset{} = changeset = Accounts.change_team_email(%Team{})
      assert changeset.required == [:email]
    end
  end

  describe "apply_team_email/3" do
    setup do
      %{team: team_fixture()}
    end

    test "requires email to change", %{team: team} do
      {:error, changeset} = Accounts.apply_team_email(team, valid_team_password(), %{})
      assert %{email: ["did not change"]} = errors_on(changeset)
    end

    test "validates email", %{team: team} do
      {:error, changeset} =
        Accounts.apply_team_email(team, valid_team_password(), %{email: "not valid"})

      assert %{email: ["must have the @ sign and no spaces"]} = errors_on(changeset)
    end

    test "validates maximum value for email for security", %{team: team} do
      too_long = String.duplicate("db", 100)

      {:error, changeset} =
        Accounts.apply_team_email(team, valid_team_password(), %{email: too_long})

      assert "should be at most 160 character(s)" in errors_on(changeset).email
    end

    test "validates email uniqueness", %{team: team} do
      %{email: email} = team_fixture()
      password = valid_team_password()

      {:error, changeset} = Accounts.apply_team_email(team, password, %{email: email})

      assert "has already been taken" in errors_on(changeset).email
    end

    test "validates current password", %{team: team} do
      {:error, changeset} =
        Accounts.apply_team_email(team, "invalid", %{email: unique_team_email()})

      assert %{current_password: ["is not valid"]} = errors_on(changeset)
    end

    test "applies the email without persisting it", %{team: team} do
      email = unique_team_email()
      {:ok, team} = Accounts.apply_team_email(team, valid_team_password(), %{email: email})
      assert team.email == email
      assert Accounts.get_team!(team.id).email != email
    end
  end

  describe "deliver_team_update_email_instructions/3" do
    setup do
      %{team: team_fixture()}
    end

    test "sends token through notification", %{team: team} do
      token =
        extract_team_token(fn url ->
          Accounts.deliver_team_update_email_instructions(team, "current@example.com", url)
        end)

      {:ok, token} = Base.url_decode64(token, padding: false)
      assert team_token = Repo.get_by(TeamToken, token: :crypto.hash(:sha256, token))
      assert team_token.team_id == team.id
      assert team_token.sent_to == team.email
      assert team_token.context == "change:current@example.com"
    end
  end

  describe "update_team_email/2" do
    setup do
      team = team_fixture()
      email = unique_team_email()

      token =
        extract_team_token(fn url ->
          Accounts.deliver_team_update_email_instructions(%{team | email: email}, team.email, url)
        end)

      %{team: team, token: token, email: email}
    end

    test "updates the email with a valid token", %{team: team, token: token, email: email} do
      assert Accounts.update_team_email(team, token) == :ok
      changed_team = Repo.get!(Team, team.id)
      assert changed_team.email != team.email
      assert changed_team.email == email
      assert changed_team.confirmed_at
      assert changed_team.confirmed_at != team.confirmed_at
      refute Repo.get_by(TeamToken, team_id: team.id)
    end

    test "does not update email with invalid token", %{team: team} do
      assert Accounts.update_team_email(team, "oops") == :error
      assert Repo.get!(Team, team.id).email == team.email
      assert Repo.get_by(TeamToken, team_id: team.id)
    end

    test "does not update email if team email changed", %{team: team, token: token} do
      assert Accounts.update_team_email(%{team | email: "current@example.com"}, token) == :error
      assert Repo.get!(Team, team.id).email == team.email
      assert Repo.get_by(TeamToken, team_id: team.id)
    end

    test "does not update email if token expired", %{team: team, token: token} do
      {1, nil} = Repo.update_all(TeamToken, set: [inserted_at: ~N[2020-01-01 00:00:00]])
      assert Accounts.update_team_email(team, token) == :error
      assert Repo.get!(Team, team.id).email == team.email
      assert Repo.get_by(TeamToken, team_id: team.id)
    end
  end

  describe "change_team_password/2" do
    test "returns a team changeset" do
      assert %Ecto.Changeset{} = changeset = Accounts.change_team_password(%Team{})
      assert changeset.required == [:password]
    end

    test "allows fields to be set" do
      changeset =
        Accounts.change_team_password(%Team{}, %{
          "password" => "new valid password"
        })

      assert changeset.valid?
      assert get_change(changeset, :password) == "new valid password"
      assert is_nil(get_change(changeset, :hashed_password))
    end
  end

  describe "update_team_password/3" do
    setup do
      %{team: team_fixture()}
    end

    test "validates password", %{team: team} do
      {:error, changeset} =
        Accounts.update_team_password(team, valid_team_password(), %{
          password: "short",
          password_confirmation: "another"
        })

      assert %{
               password: ["should be at least 6 character(s)"],
               password_confirmation: ["does not match password"]
             } = errors_on(changeset)
    end

    test "validates maximum values for password for security", %{team: team} do
      too_long = String.duplicate("db", 100)

      {:error, changeset} =
        Accounts.update_team_password(team, valid_team_password(), %{password: too_long})

      assert "should be at most 72 character(s)" in errors_on(changeset).password
    end

    test "validates current password", %{team: team} do
      {:error, changeset} =
        Accounts.update_team_password(team, "invalid", %{password: valid_team_password()})

      assert %{current_password: ["is not valid"]} = errors_on(changeset)
    end

    test "updates the password", %{team: team} do
      {:ok, team} =
        Accounts.update_team_password(team, valid_team_password(), %{
          password: "new valid password"
        })

      assert is_nil(team.password)
      assert Accounts.get_team_by_email_and_password(team.email, "new valid password")
    end

    test "deletes all tokens for the given team", %{team: team} do
      _ = Accounts.generate_team_session_token(team)

      {:ok, _} =
        Accounts.update_team_password(team, valid_team_password(), %{
          password: "new valid password"
        })

      refute Repo.get_by(TeamToken, team_id: team.id)
    end
  end

  describe "generate_team_session_token/1" do
    setup do
      %{team: team_fixture()}
    end

    test "generates a token", %{team: team} do
      token = Accounts.generate_team_session_token(team)
      assert team_token = Repo.get_by(TeamToken, token: token)
      assert team_token.context == "session"

      # Creating the same token for another team should fail
      assert_raise Ecto.ConstraintError, fn ->
        Repo.insert!(%TeamToken{
          token: team_token.token,
          team_id: team_fixture().id,
          context: "session"
        })
      end
    end
  end

  describe "get_team_by_session_token/1" do
    setup do
      team = team_fixture()
      token = Accounts.generate_team_session_token(team)
      %{team: team, token: token}
    end

    test "returns team by token", %{team: team, token: token} do
      assert session_team = Accounts.get_team_by_session_token(token)
      assert session_team.id == team.id
    end

    test "does not return team for invalid token" do
      refute Accounts.get_team_by_session_token("oops")
    end

    test "does not return team for expired token", %{token: token} do
      {1, nil} = Repo.update_all(TeamToken, set: [inserted_at: ~N[2020-01-01 00:00:00]])
      refute Accounts.get_team_by_session_token(token)
    end
  end

  describe "delete_team_session_token/1" do
    test "deletes the token" do
      team = team_fixture()
      token = Accounts.generate_team_session_token(team)
      assert Accounts.delete_team_session_token(token) == :ok
      refute Accounts.get_team_by_session_token(token)
    end
  end

  describe "deliver_team_confirmation_instructions/2" do
    setup do
      %{team: team_fixture()}
    end

    test "sends token through notification", %{team: team} do
      token =
        extract_team_token(fn url ->
          Accounts.deliver_team_confirmation_instructions(team, url)
        end)

      {:ok, token} = Base.url_decode64(token, padding: false)
      assert team_token = Repo.get_by(TeamToken, token: :crypto.hash(:sha256, token))
      assert team_token.team_id == team.id
      assert team_token.sent_to == team.email
      assert team_token.context == "confirm"
    end
  end

  describe "confirm_team/1" do
    setup do
      team = team_fixture()

      token =
        extract_team_token(fn url ->
          Accounts.deliver_team_confirmation_instructions(team, url)
        end)

      %{team: team, token: token}
    end

    test "confirms the email with a valid token", %{team: team, token: token} do
      assert {:ok, confirmed_team} = Accounts.confirm_team(token)
      assert confirmed_team.confirmed_at
      assert confirmed_team.confirmed_at != team.confirmed_at
      assert Repo.get!(Team, team.id).confirmed_at
      refute Repo.get_by(TeamToken, team_id: team.id)
    end

    test "does not confirm with invalid token", %{team: team} do
      assert Accounts.confirm_team("oops") == :error
      refute Repo.get!(Team, team.id).confirmed_at
      assert Repo.get_by(TeamToken, team_id: team.id)
    end

    test "does not confirm email if token expired", %{team: team, token: token} do
      {1, nil} = Repo.update_all(TeamToken, set: [inserted_at: ~N[2020-01-01 00:00:00]])
      assert Accounts.confirm_team(token) == :error
      refute Repo.get!(Team, team.id).confirmed_at
      assert Repo.get_by(TeamToken, team_id: team.id)
    end
  end

  describe "deliver_team_reset_password_instructions/2" do
    setup do
      %{team: team_fixture()}
    end

    test "sends token through notification", %{team: team} do
      token =
        extract_team_token(fn url ->
          Accounts.deliver_team_reset_password_instructions(team, url)
        end)

      {:ok, token} = Base.url_decode64(token, padding: false)
      assert team_token = Repo.get_by(TeamToken, token: :crypto.hash(:sha256, token))
      assert team_token.team_id == team.id
      assert team_token.sent_to == team.email
      assert team_token.context == "reset_password"
    end
  end

  describe "get_team_by_reset_password_token/1" do
    setup do
      team = team_fixture()

      token =
        extract_team_token(fn url ->
          Accounts.deliver_team_reset_password_instructions(team, url)
        end)

      %{team: team, token: token}
    end

    test "returns the team with valid token", %{team: %{id: id}, token: token} do
      assert %Team{id: ^id} = Accounts.get_team_by_reset_password_token(token)
      assert Repo.get_by(TeamToken, team_id: id)
    end

    test "does not return the team with invalid token", %{team: team} do
      refute Accounts.get_team_by_reset_password_token("oops")
      assert Repo.get_by(TeamToken, team_id: team.id)
    end

    test "does not return the team if token expired", %{team: team, token: token} do
      {1, nil} = Repo.update_all(TeamToken, set: [inserted_at: ~N[2020-01-01 00:00:00]])
      refute Accounts.get_team_by_reset_password_token(token)
      assert Repo.get_by(TeamToken, team_id: team.id)
    end
  end

  describe "reset_team_password/2" do
    setup do
      %{team: team_fixture()}
    end

    test "validates password", %{team: team} do
      {:error, changeset} =
        Accounts.reset_team_password(team, %{
          password: "short",
          password_confirmation: "another"
        })

      assert %{
               password: ["should be at least 6 character(s)"],
               password_confirmation: ["does not match password"]
             } = errors_on(changeset)
    end

    test "validates maximum values for password for security", %{team: team} do
      too_long = String.duplicate("db", 100)
      {:error, changeset} = Accounts.reset_team_password(team, %{password: too_long})
      assert "should be at most 72 character(s)" in errors_on(changeset).password
    end

    test "updates the password", %{team: team} do
      {:ok, updated_team} = Accounts.reset_team_password(team, %{password: "new valid password"})
      assert is_nil(updated_team.password)
      assert Accounts.get_team_by_email_and_password(team.email, "new valid password")
    end

    test "deletes all tokens for the given team", %{team: team} do
      _ = Accounts.generate_team_session_token(team)
      {:ok, _} = Accounts.reset_team_password(team, %{password: "new valid password"})
      refute Repo.get_by(TeamToken, team_id: team.id)
    end
  end

  describe "inspect/2 for the Team module" do
    test "does not include password" do
      refute inspect(%Team{password: "123456"}) =~ "password: \"123456\""
    end
  end
end
