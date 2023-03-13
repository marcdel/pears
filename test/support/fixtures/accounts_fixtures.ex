defmodule Pears.AccountsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Pears.Accounts` context.
  """

  def unique_team_name, do: "team#{System.unique_integer()}"
  def valid_team_password, do: "hello world!"

  def team_fixture(attrs \\ %{}) do
    {:ok, team} =
      attrs
      |> Enum.into(%{
        name: unique_team_name(),
        password: valid_team_password()
      })
      |> Pears.Accounts.register_team()

    team
  end

  def extract_team_token(fun) do
    {:ok, captured} = fun.(&"[TOKEN]#{&1}[TOKEN]")
    [_, token, _] = String.split(captured.body, "[TOKEN]")
    token
  end
end
