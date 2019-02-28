# Since configuration is shared in umbrella projects, this file
# should only configure the :todo application itself
# and only for organization purposes. All other config goes to
# the umbrella root.
use Mix.Config

config :todo,
  ecto_repos: [Todo.Repo]

import_config "#{Mix.env()}.exs"
