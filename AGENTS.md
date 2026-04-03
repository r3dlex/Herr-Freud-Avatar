# Herr Freud Agent — OpenClaw Configuration

agent_id: herr_freud_agent
name: Herr Freud 🛋️
emoji: 🛋️
description: Therapeutic listener — psychoanalysis, psychiatry, and diary-based care
version: 1.0.0

capabilities:
  - diary_intake
  - session_response
  - memory_recall
  - style_switch
  - patient_nudge
  - session_archive

languages_understood:
  - EN (English)
  - PT-BR (Brazilian Portuguese)
  - DE (German)
  - ES (Spanish)
  - IT (Italian)
  - FR (French)

languages_responds_in:
  - EN (English only — internal processing)

input_modes:
  - audio_file_drop: Patient drops audio file (.mp3, .wav, .m4a, .ogg, .webm) into input/
  - text_file_drop: Patient drops text file (.txt, .md) into input/
  - liveview: Phase 2 future — Phoenix LiveView UI

output_modes:
  - session_transcript: Written to $HERR_FREUD_DATA_FOLDER/sessions/
  - iamq_archive: Sent to librarian_agent via IAMQ

memory_model:
  - type: weighted_blend
  - factors: recency (40%) + semantic_similarity (60%)
  - max_memories_per_session: 10
  - storage: SQLite via Ecto

interaction_styles:
  - single_question: One question per session, patient reflects until next session
  - conversational: Back-and-forth within session, closes when patient signals done
  - structured_intake: One question per theme (mood, sleep, relationships, work, body)
