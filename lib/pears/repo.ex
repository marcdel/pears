defmodule Pears.Repo do
  use Ecto.Repo,
    otp_app: :pears,
    adapter: Ecto.Adapters.Postgres
end
