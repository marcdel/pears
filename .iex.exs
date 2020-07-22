File.exists?(Path.expand("~/.iex.exs")) && import_file("~/.iex.exs")

alias Pears.Boundary.TeamManager
alias Pears.Boundary.TeamSession
alias Pears.Core
alias Pears.Core.{Pear, Recommendator, Team, Track}
alias Pears.Persistence
alias Pears.Persistence.{PearRecord, TeamRecord, TrackRecord}
