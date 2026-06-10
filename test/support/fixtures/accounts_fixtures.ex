defmodule Pears.AccountsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Pears.Accounts` context.
  """

  def unique_team_name, do: "team#{System.unique_integer()}"
  def unique_team_email, do: "team#{System.unique_integer()}@example.com"
  def valid_team_password, do: "hello world!"

  def valid_team_attributes(attrs \\ %{}) do
    Enum.into(attrs, %{
      name: unique_team_name(),
      email: unique_team_email(),
      password: valid_team_password()
    })
  end

  def team_fixture(attrs \\ %{}) do
    {:ok, team} =
      attrs
      |> valid_team_attributes()
      |> Pears.Accounts.register_team()

    team
  end

  # Registration auto-confirms teams; the email confirmation flows still
  # need a team without a confirmed_at to exercise their edge cases.
  def unconfirmed_team_fixture(attrs \\ %{}) do
    attrs
    |> team_fixture()
    |> Ecto.Changeset.change(confirmed_at: nil)
    |> Pears.Repo.update!()
  end

  def extract_team_token(fun) do
    {:ok, captured_email} = fun.(&"[TOKEN]#{&1}[TOKEN]")
    [_, token | _] = String.split(captured_email.text_body, "[TOKEN]")
    token
  end
end
