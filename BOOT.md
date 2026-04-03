# Herr Freud — Startup Sequence (BOOT.md)

## Startup Order

1. **Load environment**: Read all env vars (MINIMAX_API_KEY, IAMQ_*, HERR_FREUD_*, STT_*)
2. **Ecto startup**: Start Repo (HerrFreud.Repo), run pending migrations
3. **Seed styles**: Ensure 3 interaction styles exist in interaction_styles table
4. **Start IAMQ HttpClient**: Begin polling inbox
5. **Start IAMQ WsClient**: Establish WebSocket connection
6. **Start Input.Watcher**: Begin watching $HERR_FREUD_DATA_FOLDER/input/
7. **Start Style.Manager**: Load active style from DB
8. **Start Cron.Handler**: Register daily_nudge_check and weekly_summary schedules
9. **Log ready**: "Herr Freud is ready."

## IAMQ Registration

On first connection (both HTTP and WS), Herr Freud registers with IAMQ:

```json
{
  "agent_id": "herr_freud_agent",
  "capabilities": ["diary_intake", "session_response", "memory_recall", "style_switch", "patient_nudge", "session_archive"]
}
```

## Cron Registration

On startup, Cron.Handler registers two cron jobs via IAMQ:

```
daily_nudge_check    → 0 20 * * * (20:00 UTC daily)
weekly_summary       → 0 9 * * 1 (09:00 UTC every Monday)
```

## Database Migrations

On every startup, Repo runs pending migrations:

```bash
mix ecto.migrate
```

If no migrations exist yet, they are created via `mix ecto.gen.migration <name>`.

## Failure Handling

If IAMQ service is unreachable:
- HTTP client falls back to file-based queue at $IAMQ_QUEUE_PATH
- WS client retries connection every 30 seconds
- Log: "IAMQ unreachable, using file fallback"

If MiniMax API key is missing:
- Application fails to start with clear error message
- Log: "MINIMAX_API_KEY environment variable is required"

If STT sidecar is unreachable:
- Audio file drops are queued in a retry folder
- Text mode continues to work normally
- Log: "STT sidecar unreachable, audio sessions will retry"
