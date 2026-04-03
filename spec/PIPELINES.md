# Pipelines — Herr Freud

## Session Pipeline

```
Input File → Input.Watcher → Session.Processor → Response
                                    ↓
                              Memory Retrieval
                                    ↓
                              LLM Generation
                                    ↓
                              Memory Distillation
                                    ↓
                              Output Writer → File
                                    ↓
                              IAMQ → Librarian
```

## Nudge Pipeline

```
Cron (20:00 UTC) → Cron.Handler → Check Last Session
                                          ↓
                         No session in 2 days? → Nudge.Generator
                                                        ↓
                                                  Output.Writer
                                                        ↓
                                                  IAMQ → Librarian
```

## Weekly Summary Pipeline

```
Cron (09:00 UTC Monday) → Cron.Handler → Sessions Since 7 Days
                                           ↓
                                    LLM Summary
                                           ↓
                                    IAMQ → Librarian
```

## IAMQ Message Flow

### Inbound
```
IAMQ → HttpClient.poll → handle_inbox_message
                           ├── style_switch → Style.Manager
                           ├── cron::* → Cron.Handler
                           └── session_request → Session.Processor
```

### Outbound
```
Session complete → HttpClient.send → librarian_agent
                                          ↓
                                    Obsidian Vault
```
