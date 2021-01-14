Mox.defmock(Pears.MockSlackClient, for: Pears.SlackClient.Behaviour)
Application.put_env(:pears, :slack_client, Pears.MockSlackClient)

ExUnit.start()
Ecto.Adapters.SQL.Sandbox.mode(Pears.Repo, :manual)
