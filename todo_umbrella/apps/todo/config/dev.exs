# Since configuration is shared in umbrella projects, this file
# should only configure the :todo application itself
# and only for organization purposes. All other config goes to
# the umbrella root.
use Mix.Config

# Configure your database
config :todo, Todo.Repo,
  username: "postgres",
  password: "postgres",
  database: "todo_dev",
  hostname: "localhost",
  pool_size: 10
