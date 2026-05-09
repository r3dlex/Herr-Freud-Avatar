import Config

if config_env() == :prod do
  database_path =
    System.get_env("HERR_FREUD_DB_PATH") || raise """
    environment variable HERR_FREUD_DB_PATH is missing.
    For example: /data/herr_freud.db
    """

  config :herr_freud, HerrFreud.Repo,
    database: database_path

  minmax_api_key = System.get_env("MINIMAX_API_KEY") || raise """
    environment variable MINIMAX_API_KEY is missing.
    """

  config :herr_freud, :minimax_api_key, minmax_api_key

  stt_sidecar_url = System.get_env("STT_SIDECAR_URL") || "http://stt-sidecar:9001"
  config :herr_freud, :stt_sidecar_url, stt_sidecar_url

  data_folder = System.get_env("HERR_FREUD_DATA_FOLDER") || raise """
    environment variable HERR_FREUD_DATA_FOLDER is missing.
    """
  config :herr_freud, :herr_freud_data_folder, data_folder

  # Bumblebee/EXLA requires cmake to be installed in the Docker build environment
  # (EXLA is a NIF that wraps XLA, and its system_tex feature links libdeflate).
  # If local Bumblebee fails to load, the application falls back to the centralized
  # embeddings service via the EMBEDDINGS_URL environment variable.
  config :herr_freud, :embeddings_mod, HerrFreud.Embeddings.Bumblebee
end
