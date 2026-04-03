import Config

config :herr_freud, HerrFreud.Repo,
  database: "priv/herr_freud.db",
  pool_size: 5,
  stacktrace: true,
  show_sensitive_data_on_connection_error: true
