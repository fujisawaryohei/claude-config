<!-- MIT License - Copyright (c) 2026 Affaan Mustafa - https://github.com/affaan-m/everything-claude-code -->
---
description: Save current session state to a dated file in ~/.claude/sessions/ so work can be resumed in a future session with full context.
---

# Save Session Command

Capture everything that happened in this session — what was built, what worked, what failed, what's left — and write it to a dated file so the next session can pick up exactly where this one left off.

## When to Use

- End of a work session before closing Claude Code
- Before hitting context limits (run this first, then start a fresh session)
- After solving a complex problem you want to remember
- Any time you need to hand off context to a future session

## Process

### Step 1: Gather context

Before writing the file, collect:

- Read all files modified during this session (use git diff or recall from conversation)
- Review what was discussed, attempted, and decided
- Note any errors encountered and how they were resolved (or not)
- Check current test/build status if relevant

### Step 2: Create the sessions folder if it doesn't exist

```bash
mkdir -p ~/.claude/sessions
```

### Step 3: Write the session file

Create `~/.claude/sessions/YYYY-MM-DD-<short-id>-session.tmp`, using today's actual date and a short-id:

- Allowed characters: lowercase `a-z`, digits `0-9`, hyphens `-`
- Minimum length: 8 characters

### Step 4: Populate the file with all sections

Write every section honestly. Do not skip sections — write "Nothing yet" or "N/A" if a section genuinely has no content.

### Step 5: Show the file to the user

After writing, display the full contents and ask for confirmation before closing.

---

## Session File Format

```markdown
# Session: YYYY-MM-DD

**Started:** [approximate time if known]
**Last Updated:** [current time]
**Project:** [project name or path]
**Topic:** [one-line summary of what this session was about]

---

## What We Are Building
[1-3 paragraphs describing the feature, bug fix, or task]

---

## What WORKED (with evidence)
- **[thing that works]** — confirmed by: [specific evidence]

---

## What Did NOT Work (and why)
- **[approach tried]** — failed because: [exact reason / error message]

---

## What Has NOT Been Tried Yet
- [approach / idea]

---

## Current State of Files

| File | Status | Notes |
| ---- | ------ | ----- |
| `path/to/file.ts` | ✅ Complete | [what it does] |
| `path/to/file.ts` | 🔄 In Progress | [what's done, what's left] |
| `path/to/file.ts` | ❌ Broken | [what's wrong] |

---

## Decisions Made
- **[decision]** — reason: [why this was chosen over alternatives]

---

## Blockers & Open Questions
- [blocker / open question]

---

## Exact Next Step
[The single most important thing to do when resuming]
```

## Notes

- Each session gets its own file — never append to a previous session's file
- The "What Did NOT Work" section is the most critical
- The file is meant to be read by Claude at the start of the next session via `/resume-session`
- Use the canonical global session store: `~/.claude/sessions/`
