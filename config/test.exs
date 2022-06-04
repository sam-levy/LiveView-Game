import Config

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :game, GameWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "UzyMWJMhWWp/9B8SyFNpgwbNPyZgVAJkbjALUclhRvV8ia47slQDkBKj41Cb4pbe",
  server: false

# Print only warnings and errors during test
config :logger, level: :warn

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime
