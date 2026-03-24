<!-- MIT License - Copyright (c) 2026 Affaan Mustafa - https://github.com/affaan-m/everything-claude-code -->
---
description: Load the most recent session file from ~/.claude/sessions/ and resume work with full context from where the last session ended.
---

# Resume Session Command

Load the last saved session state and orient fully before doing any work.
This command is the counterpart to `/save-session`.

## When to Use

- Starting a new session to continue work from a previous day
- After starting a fresh session due to context limits
- When handing off a session file from another source

## Usage

```
/resume-session                                                      # loads most recent file in ~/.claude/sessions/
/resume-session 2024-01-15                                           # loads most recent session for that date
/resume-session ~/.claude/sessions/2024-01-15-abc123de-session.tmp  # loads a specific file
```

## Process

### Step 1: Find the session file

If no argument provided:
1. Check `~/.claude/sessions/`
2. Pick the most recently modified `*-session.tmp` file
3. If folder is empty, tell the user to run `/save-session` first

### Step 2: Read the entire session file

Read the complete file. Do not summarize yet.

### Step 3: Confirm understanding

Respond with a structured briefing in this exact format:

```
SESSION LOADED: [actual resolved path to the file]
════════════════════════════════════════════════

PROJECT: [project name / topic from file]

WHAT WE'RE BUILDING:
[2-3 sentence summary in your own words]

CURRENT STATE:
✅ Working: [count] items confirmed
🔄 In Progress: [list files that are in progress]
🗒️ Not Started: [list planned but untouched]

WHAT NOT TO RETRY:
[list every failed approach with its reason — this is critical]

OPEN QUESTIONS / BLOCKERS:
[list any blockers or unanswered questions]

NEXT STEP:
[exact next step if defined in the file]

════════════════════════════════════════════════
Ready to continue. What would you like to do?
```

### Step 4: Wait for the user

Do NOT start working automatically. Do NOT touch any files. Wait for the user to say what to do next.

## Notes

- Never modify the session file when loading it — it's a read-only historical record
- "What Not To Retry" must always be shown — it's too important to miss
- After resuming, the user may want to run `/save-session` again at the end of the new session
