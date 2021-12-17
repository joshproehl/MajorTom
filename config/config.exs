# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

config :major_tom,
  ecto_repos: [MajorTom.Repo],
  flherne_sync_http_adapter: MajorTom.HTTPAdapter,
  enable_flherne_sync: true

# Configures the endpoint
config :major_tom, MajorTomWeb.Endpoint,
  url: [host: "localhost"],
  render_errors: [view: MajorTomWeb.ErrorView, accepts: ~w(html json), layout: false],
  pubsub_server: MajorTom.PubSub,
  live_view: [signing_salt: "x16fTVou"]

# Configures the mailer
#
# By default it uses the "Local" adapter which stores the emails
# locally. You can see the emails in your browser, at "/dev/mailbox".
#
# For production it's recommended to configure a different adapter
# at the `config/runtime.exs`.
config :major_tom, MajorTom.Mailer, adapter: Swoosh.Adapters.Local

# Swoosh API client is needed for adapters other than SMTP.
config :swoosh, :api_client, false

# Configure esbuild (the version is required)
config :esbuild,
  version: "0.12.18",
  default: [
    args:
      ~w(js/app.js --bundle --target=es2016 --outdir=../priv/static/assets --external:/fonts/* --external:/images/*),
    cd: Path.expand("../assets", __DIR__),
    env: %{"NODE_PATH" => Path.expand("../deps", __DIR__)}
  ]

config :sentry,
  dsn: "${MAJOR_TOM_SENTRY_DSN}",
  environment_name: Mix.env(),
  enable_source_code_context: true,
  root_source_code_path: File.cwd!(),
  tags: %{
    env: "production"
  },
  release: "marvin@#{Mix.Project.config[:version]}",
  included_environments: [:prod]

config :major_tom, MajorTom.IrcRobot,
  adapter: Hedwig.Adapters.IRC,
  server: "irc.esper.net",
  port: 6697,
  ssl?: true,
  name: "MajorTom",
  full_name: "MajorTom, a robotic SpaceX Fan",
  aka: "^",
  rooms: [
    {"#MajorTomDev", ""},
  ],
  responders: [
    {Hedwig.Responders.Help, []},
    {Hedwig.Responders.Ping, []},
    {MajorTom.Responders.Flherne.Bankrupt, []},
    {MajorTom.Responders.Flherne.Banned, []},
    {MajorTom.Responders.Flherne.Book, []},
    {MajorTom.Responders.Flherne.Colloid, []},
    {MajorTom.Responders.Flherne.Frog, []},
    {MajorTom.Responders.Flherne.Lunch, []},
    {MajorTom.Responders.Flherne.Mission, []},
    {MajorTom.Responders.Flherne.Misc, []},
    {MajorTom.Responders.Flherne.Outcome, []},
    {MajorTom.Responders.Flherne.Stupid, []},
  ]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
