# Herr Freud — Periodic Tasks (HEARTBEAT.md)

## Heartbeat Schedule

Herr Freud performs periodic background tasks independent of patient sessions.

## Every 60 seconds (HTTP poll)
- **IAMQ HttpClient** polls the IAMQ inbox for new messages
- Processes: style_switch, session_request, cron::* messages

## Every 5 minutes
- **Input.Watcher** health check: verify input directory is accessible
- **Session cleanup**: Remove stale retry files from input/.retry/

## Every 20 minutes
- **Memory maintenance**: Recompute recency scores for memories older than 7 days
  (recency score decays, but this keeps the blend fresh)

## Daily at 20:00 UTC (daily_nudge_check)
- **Cron.Handler** checks last session date from sessions table
- If no session within HERR_FREUD_NUDGE_AFTER_DAYS (default 2):
  - Generate nudge via MiniMax
  - Write to $HERR_FREUD_DATA_FOLDER/nudges/YYYY-MM-DD_nudge.md
  - Insert into nudges table
  - Send to librarian_agent via IAMQ
- No nudge fires more than once per day

## Weekly at 09:00 UTC on Monday (weekly_summary)
- **Cron.Handler** queries sessions from the past 7 days
- Generates brief summary via MiniMax
- Sends to librarian_agent via IAMQ as weekly_summary.md

## On session completion (post-session)
- **Memory distiller**: Extract 1-3 memory statements from session
- **Profile updater**: Identify new facts for patient_profile
- **Output writer**: Write session transcript to sessions/
- **IAMQ archiver**: Send to librarian_agent

## Error Handling
- All periodic tasks are supervised — if one crashes, the supervisor restarts it
- Failed nudge generation is logged and retried next cycle
- Failed IAMQ sends are queued for retry
