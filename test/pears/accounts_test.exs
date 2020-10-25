defmodule Pears.AccountsTest do
  use Pears.DataCase

  alias Pears.Accounts
  import Pears.AccountsFixtures
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

    test "validates name and password when given" do
      {:error, changeset} = Accounts.register_team(%{name: " ", password: "short"})

      assert %{
               name: ["can't be blank"],
               password: ["should be at least 6 character(s)"]
             } = errors_on(changeset)
    end

    test "validates maximum values for name and password for security" do
      too_long = String.duplicate("db", 100)
      {:error, changeset} = Accounts.register_team(%{name: too_long, password: too_long})
      assert "should be at most 160 character(s)" in errors_on(changeset).name
      assert "should be at most 80 character(s)" in errors_on(changeset).password
    end

    test "validates name uniqueness" do
      %{name: name} = team_fixture()
      {:error, changeset} = Accounts.register_team(%{name: name})
      assert "has already been taken" in errors_on(changeset).name

      # Now try with the upper cased name too, to check that name case is ignored.
      {:error, changeset} = Accounts.register_team(%{name: String.upcase(name)})
      assert "has already been taken" in errors_on(changeset).name
    end

    test "registers teams with a hashed password" do
      name = unique_team_name()
      {:ok, team} = Accounts.register_team(%{name: name, password: valid_team_password()})
      assert team.name == name
      assert is_binary(team.hashed_password)
      assert is_nil(team.password)
      refute team.enabled
    end
  end

  describe "change_team_registration/2" do
    test "returns a changeset" do
      assert %Ecto.Changeset{} = changeset = Accounts.change_team_registration(%Team{})
      assert changeset.required == [:password, :name]
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

  describe "change_team_password/2" do
    test "returns a team changeset" do
      assert %Ecto.Changeset{} = changeset = Accounts.change_team_password(%Team{})
      assert changeset.required == [:password]
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

      assert "should be at most 80 character(s)" in errors_on(changeset).password
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
      assert Accounts.get_team_by_name_and_password(team.name, "new valid password")
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

  describe "delete_session_token/1" do
    test "deletes the token" do
      team = team_fixture()
      token = Accounts.generate_team_session_token(team)
      assert Accounts.delete_session_token(token) == :ok
      refute Accounts.get_team_by_session_token(token)
    end
  end

  describe "inspect/2" do
    test "does not include password" do
      refute inspect(%Team{password: "123456"}) =~ "password: \"123456\""
    end
  end
end
