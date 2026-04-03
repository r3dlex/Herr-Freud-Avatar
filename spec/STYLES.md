# Interaction Styles — Herr Freud

## Style 1: single_question

**Best for**: Patients who need space to process.

Herr Freud:
1. Listens fully to the entire entry
2. Reflects briefly (1-2 sentences)
3. Asks exactly ONE question
4. Patient has until the next session to sit with it

## Style 2: conversational

**Best for**: Active processors who think through talking.

Herr Freud:
1. Asks a question
2. Patient responds
3. Follows up with a deeper question
4. Repeats until patient signals done or max turns (10)
5. Closes session warmly

## Style 3: structured_intake

**Best for**: Patients who benefit from regular check-ins and structure.

Default themes (configurable in DB):
- Mood
- Sleep
- Relationships
- Work
- Body

One question per theme, records response before moving to next.

## Switching Styles

Via IAMQ:
```json
{
  "to": "herr_freud_agent",
  "subject": "style_switch",
  "body": { "style": "conversational" }
}
```

Via companion file:
```
style: conversational
```
