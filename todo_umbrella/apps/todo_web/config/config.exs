# Since configuration is shared in umbrella projects, this file
# should only configure the :todo_web application itself
# and only for organization purposes. All other config goes to
# the umbrella root.
use Mix.Config

# General application configuration
config :todo_web,
  ecto_repos: [Todo.Repo],
  generators: [context_app: :todo]

# Configures the endpoint
config :todo_web, TodoWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "UJe3S4nM6M6eEDcyvQ+wy5wYycWVEhIzyCLVV5cpr7VcZZeepCu17O03z6qmK8j/",
  render_errors: [view: TodoWeb.ErrorView, accepts: ~w(html json)],
  pubsub: [name: TodoWeb.PubSub, adapter: Phoenix.PubSub.PG2]

config :phoenix, :template_engines,
  eex: TodoWeb.Components.Engine

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
