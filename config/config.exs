import Config

config :herr_freud,
  ecto_repos: [HerrFreud.Repo],
  generators: [binary_id: true],
  minimax_api_key: System.get_env("MINIMAX_API_KEY"),
  minimax_model: System.get_env("MINIMAX_MODEL") || "abab6.5s-chat",
  minimax_embedding_model: System.get_env("MINIMAX_EMBEDDING_MODEL") || "embo-01",
  iamq_http_url: System.get_env("IAMQ_HTTP_URL") || "http://127.0.0.1:18790",
  iamq_ws_url: System.get_env("IAMQ_WS_URL") || "ws://127.0.0.1:18793/ws",
  iamq_agent_id: System.get_env("IAMQ_AGENT_ID") || "herr_freud_agent",
  iamq_queue_path: System.get_env("IAMQ_QUEUE_PATH"),
  iamq_heartbeat_ms: 300_000,
  iamq_poll_ms: 60_000,
  stt_sidecar_url: System.get_env("STT_SIDECAR_URL") || "http://stt-sidecar:9001",
  stt_model: System.get_env("STT_MODEL") || "large-v3",
  herr_freud_db_path: System.get_env("HERR_FREUD_DB_PATH") || "priv/herr_freud.db",
  herr_freud_data_folder: System.get_env("HERR_FREUD_DATA_FOLDER") || "./data",
  herr_freud_log_level: System.get_env("HERR_FREUD_LOG_LEVEL") || "info",
  herr_freud_nudge_after_days: 2,
  herr_freud_memory_recency_weight: 0.4,
  herr_freud_memory_similarity_weight: 0.6,
  llm_mod: HerrFreud.LLM.MiniMax,
  embeddings_mod: HerrFreud.Embeddings.MiniMax,
  stt_mod: HerrFreud.STT.Client,
  iamq_http_mod: HerrFreud.IAMQ.HttpClient

config :logger, level: String.to_atom(Application.get_env(:herr_freud, :herr_freud_log_level, "info"))

import_config "#{config_env()}.exs"
