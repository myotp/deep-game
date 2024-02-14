import Config

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :deep_game, DeepGameWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "QswyBu2XKMmKDbc66uC9bBwpA/4VTivcN5x+z1wb6+VXEs7lHrS6Ie6EhEXaAWMF",
  server: false

# Print only warnings and errors during test
config :logger, level: :warning

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime
